#!/usr/bin/env bun

declare const Bun: {
	file(path: string | URL): {
		text(): Promise<string>;
	};
};

declare const process: {
	env: Record<string, string | undefined>;
	argv: string[];
	exit(code?: number): never;
};

declare global {
	interface ImportMeta {
		main: boolean;
	}
}

const CLICKUP_API_BASE = 'https://api.clickup.com/api/v2';
const DEFAULT_CONFIG_URL = new URL(
	'./clickup-weekly-meetings.json',
	import.meta.url,
);
const DRY_RUN_FLAG = '--dry-run';
const CONFIG_FLAG = '--config';
const ENTRY_START_HOUR = 12;
const DUTY_DAY_OFF_SUMMARY = 'Day off due to duty last weekend';

const WEEKDAYS = [
	'monday',
	'tuesday',
	'wednesday',
	'thursday',
	'friday',
	'saturday',
	'sunday',
] as const;

export type Weekday = (typeof WEEKDAYS)[number];

export interface MeetingConfig {
	name: string;
	taskIdentifier: string;
	weekday: Weekday;
	durationMinutes: number;
}

interface ScheduleConfig {
	meetings: MeetingConfig[];
	dutyCalendarUrl?: string;
}

interface ClickUpUser {
	id: number;
	username: string;
}

interface Team {
	id: string;
	name: string;
}

interface TaskResponse {
	id: string;
}

export interface TimeEntry {
	id: string;
	start: string;
	duration: string;
	description: string;
	task: {
		id: string;
		name: string;
	} | null;
}

interface TimeEntriesResponse {
	data: TimeEntry[];
}

interface ResolvedMeeting extends MeetingConfig {
	taskId: string;
}

export interface SyncPlanItem {
	action: 'create' | 'update' | 'unchanged';
	meetings: ResolvedMeeting[];
	taskId: string;
	weekday: Weekday;
	start: Date;
	durationMs: number;
	existingEntry?: TimeEntry;
}

interface CliOptions {
	configPath: string | URL;
	dryRun: boolean;
}

function getApiKey(): string {
	const apiKey = process.env.CLICKUP_API_KEY;
	if (!apiKey) {
		throw new Error('Missing CLICKUP_API_KEY in environment');
	}
	return apiKey;
}

async function clickupRequest<T>(
	endpoint: string,
	init?: RequestInit,
): Promise<T> {
	const response = await fetch(`${CLICKUP_API_BASE}${endpoint}`, {
		...init,
		headers: {
			Authorization: getApiKey(),
			'Content-Type': 'application/json',
			...(init?.headers ?? {}),
		},
	});

	if (!response.ok) {
		const body = await response.text();
		throw new Error(
			`ClickUp API error (${response.status}) on ${endpoint}: ${body}`,
		);
	}

	return (await response.json()) as T;
}

async function getAuthorizedUser(): Promise<ClickUpUser> {
	const response = await clickupRequest<{user: ClickUpUser}>('/user');
	return response.user;
}

async function getTeams(): Promise<Team[]> {
	const response = await clickupRequest<{teams: Team[]}>('/team');
	return response.teams;
}

async function resolveTaskId(
	taskIdentifier: string,
	teamId: string,
): Promise<string> {
	try {
		const response = await clickupRequest<TaskResponse>(
			`/task/${taskIdentifier}?custom_task_ids=true&team_id=${teamId}`,
		);
		return response.id;
	} catch {
		const response = await clickupRequest<TaskResponse>(
			`/task/${taskIdentifier}`,
		);
		return response.id;
	}
}

export function getCurrentWeekDates(now = new Date()): Map<Weekday, Date> {
	const dayOfWeek = now.getDay();
	const daysToMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
	const monday = new Date(now);
	monday.setDate(now.getDate() - daysToMonday);
	monday.setHours(ENTRY_START_HOUR, 0, 0, 0);

	return new Map(
		WEEKDAYS.map((weekday, index) => {
			const date = new Date(monday);
			date.setDate(monday.getDate() + index);
			return [weekday, date];
		}),
	);
}

function getWeekRange(now = new Date()): {start: Date; end: Date} {
	const weekDates = getCurrentWeekDates(now);
	const start = new Date(weekDates.get('monday')!);
	const end = new Date(weekDates.get('sunday')!);
	start.setHours(0, 0, 0, 0);
	end.setHours(23, 59, 59, 999);
	return {start, end};
}

function formatIcsDateOnly(date: Date): string {
	const year = date.getFullYear().toString().padStart(4, '0');
	const month = (date.getMonth() + 1).toString().padStart(2, '0');
	const day = date.getDate().toString().padStart(2, '0');
	return `${year}${month}${day}`;
}

export function hasDutyDayOffOnFriday(
	icsContents: string,
	now = new Date(),
): boolean {
	const friday = getCurrentWeekDates(now).get('friday')!;
	const fridayDate = formatIcsDateOnly(friday);
	const unfoldedContents = icsContents.replaceAll(/\r?\n[ \t]/gu, '');
	const eventBlocks = unfoldedContents.match(
		/BEGIN:VEVENT\r?\n[\s\S]*?\r?\nEND:VEVENT/gu,
	);

	return (
		eventBlocks?.some(eventBlock => {
			const lines = eventBlock.split(/\r?\n/u);
			const summary = lines.find(line => line.startsWith('SUMMARY:'));
			const start = lines.find(line => line.startsWith('DTSTART'));

			return (
				summary === `SUMMARY:${DUTY_DAY_OFF_SUMMARY}` &&
				start?.match(/^DTSTART(?:;[^:]*)?:(\d{8})/u)?.[1] === fridayDate
			);
		}) ?? false
	);
}

async function hasDutyDayOffThisFriday(calendarUrl: string): Promise<boolean> {
	let response: Response;
	try {
		response = await fetch(calendarUrl);
	} catch {
		throw new Error('Could not fetch duty calendar');
	}

	if (!response.ok) {
		throw new Error(`Duty calendar request failed (${response.status})`);
	}

	return hasDutyDayOffOnFriday(await response.text());
}

async function getWeekEntries(
	teamId: string,
	userId: number,
): Promise<TimeEntry[]> {
	const {start, end} = getWeekRange();
	const response = await clickupRequest<TimeEntriesResponse>(
		`/team/${teamId}/time_entries?start_date=${start.getTime()}&end_date=${end.getTime()}&assignee=${userId}`,
	);
	return response.data ?? [];
}

export function buildSyncPlan(
	meetings: ResolvedMeeting[],
	existingEntries: TimeEntry[],
	now = new Date(),
): SyncPlanItem[] {
	const weekDates = getCurrentWeekDates(now);
	const groups = new Map<string, Omit<SyncPlanItem, 'action'>>();

	for (const meeting of meetings) {
		const key = `${meeting.taskId}:${meeting.weekday}`;
		const existingGroup = groups.get(key);
		if (existingGroup) {
			existingGroup.meetings.push(meeting);
			existingGroup.durationMs += meeting.durationMinutes * 60 * 1000;
			continue;
		}

		groups.set(key, {
			meetings: [meeting],
			taskId: meeting.taskId,
			weekday: meeting.weekday,
			start: new Date(weekDates.get(meeting.weekday)!),
			durationMs: meeting.durationMinutes * 60 * 1000,
		});
	}

	return [...groups.values()].map(group => {
		const existingEntry = existingEntries.find(
			entry =>
				entry.task?.id === group.taskId &&
				Number.parseInt(entry.start, 10) === group.start.getTime(),
		);

		if (!existingEntry) {
			return {
				action: 'create',
				...group,
			};
		}

		const needsUpdate =
			Number.parseInt(existingEntry.duration, 10) !== group.durationMs ||
			existingEntry.description !== '';

		return {
			action: needsUpdate ? 'update' : 'unchanged',
			...group,
			existingEntry,
		};
	});
}

async function createTimeEntry(
	teamId: string,
	userId: number,
	item: SyncPlanItem,
): Promise<void> {
	await clickupRequest(`/team/${teamId}/time_entries`, {
		method: 'POST',
		body: JSON.stringify({
			start: item.start.getTime().toString(),
			duration: item.durationMs.toString(),
			assignee: userId,
			tid: item.taskId,
		}),
	});
}

async function updateTimeEntry(
	teamId: string,
	item: SyncPlanItem,
): Promise<void> {
	if (!item.existingEntry) {
		throw new Error(
			`Missing existing entry for ${item.taskId} on ${item.weekday}`,
		);
	}

	await clickupRequest(
		`/team/${teamId}/time_entries/${item.existingEntry.id}`,
		{
			method: 'PUT',
			body: JSON.stringify({
				start: item.start.getTime().toString(),
				duration: item.durationMs.toString(),
				tid: item.taskId,
				description: '',
			}),
		},
	);
}

function assertString(value: unknown, field: string, index: number): string {
	if (typeof value !== 'string' || value.trim() === '') {
		throw new Error(`meetings[${index}].${field} must be a non-empty string`);
	}
	return value.trim();
}

export function parseScheduleConfig(value: unknown): ScheduleConfig {
	if (
		typeof value !== 'object' ||
		value === null ||
		!('meetings' in value) ||
		!Array.isArray(value.meetings)
	) {
		throw new Error('Schedule config must contain a meetings array');
	}

	const meetings = value.meetings.map((item: unknown, index: number) => {
		if (typeof item !== 'object' || item === null) {
			throw new Error(`meetings[${index}] must be an object`);
		}

		const record = item as Record<string, unknown>;
		const weekday = assertString(record.weekday, 'weekday', index);
		if (!WEEKDAYS.includes(weekday as Weekday)) {
			throw new Error(`Invalid weekday for meetings[${index}]: ${weekday}`);
		}

		if (
			typeof record.durationMinutes !== 'number' ||
			!Number.isInteger(record.durationMinutes) ||
			record.durationMinutes <= 0
		) {
			throw new Error(
				`meetings[${index}].durationMinutes must be a positive integer`,
			);
		}

		return {
			name: assertString(record.name, 'name', index),
			taskIdentifier: assertString(
				record.taskIdentifier,
				'taskIdentifier',
				index,
			),
			weekday: weekday as Weekday,
			durationMinutes: record.durationMinutes,
		};
	});

	const calendarUrlValue = (value as Record<string, unknown>).dutyCalendarUrl;
	let dutyCalendarUrl: string | undefined;
	if (calendarUrlValue !== undefined) {
		if (
			typeof calendarUrlValue !== 'string' ||
			calendarUrlValue.trim() === ''
		) {
			throw new Error('dutyCalendarUrl must be a non-empty HTTPS URL');
		}

		const trimmedUrl = calendarUrlValue.trim();
		let parsedUrl: URL;
		try {
			parsedUrl = new URL(trimmedUrl);
		} catch {
			throw new Error('dutyCalendarUrl must be a valid HTTPS URL');
		}
		if (parsedUrl.protocol !== 'https:') {
			throw new Error('dutyCalendarUrl must be a valid HTTPS URL');
		}
		dutyCalendarUrl = trimmedUrl;
	}

	return {meetings, dutyCalendarUrl};
}

function parseCliOptions(arguments_: string[]): CliOptions {
	let configPath: string | URL = DEFAULT_CONFIG_URL;
	let dryRun = false;

	for (let index = 0; index < arguments_.length; index++) {
		const argument = arguments_[index];
		if (argument === DRY_RUN_FLAG) {
			dryRun = true;
			continue;
		}
		if (argument === CONFIG_FLAG) {
			const nextArgument = arguments_[index + 1];
			if (!nextArgument) {
				throw new Error(`${CONFIG_FLAG} requires a file path`);
			}
			configPath = nextArgument;
			index++;
			continue;
		}
		throw new Error(`Unknown argument: ${argument}`);
	}

	return {configPath, dryRun};
}

async function loadScheduleConfig(
	configPath: string | URL,
): Promise<ScheduleConfig> {
	const contents = await Bun.file(configPath).text();
	return parseScheduleConfig(JSON.parse(contents) as unknown);
}

async function main(): Promise<void> {
	const {configPath, dryRun} = parseCliOptions(process.argv.slice(2));
	const config = await loadScheduleConfig(configPath);
	let meetings = config.meetings;

	if (
		config.dutyCalendarUrl &&
		(await hasDutyDayOffThisFriday(config.dutyCalendarUrl))
	) {
		const fridayMeetingCount = meetings.filter(
			meeting => meeting.weekday === 'friday',
		).length;
		meetings = meetings.filter(meeting => meeting.weekday !== 'friday');
		console.log(
			`Duty day off this Friday: skipped ${fridayMeetingCount} Friday meeting(s)`,
		);
	}

	if (meetings.length === 0) {
		console.log(`No weekly meetings configured in ${String(configPath)}`);
		return;
	}

	const [user, teams] = await Promise.all([getAuthorizedUser(), getTeams()]);
	if (teams.length === 0) {
		throw new Error('No ClickUp teams available for current account');
	}

	const teamIdFromEnvironment = process.env.CLICKUP_TEAM_ID;
	const team = teamIdFromEnvironment
		? teams.find(item => item.id === teamIdFromEnvironment)
		: teams[0];

	if (!team) {
		throw new Error(
			`Could not find team for CLICKUP_TEAM_ID=${teamIdFromEnvironment}`,
		);
	}

	const taskIds = new Map<string, string>();
	const resolvedMeetings: ResolvedMeeting[] = [];
	for (const meeting of meetings) {
		let taskId = taskIds.get(meeting.taskIdentifier);
		if (!taskId) {
			taskId = await resolveTaskId(meeting.taskIdentifier, team.id);
			taskIds.set(meeting.taskIdentifier, taskId);
		}
		resolvedMeetings.push({...meeting, taskId});
	}

	const existingEntries = await getWeekEntries(team.id, user.id);
	const plan = buildSyncPlan(resolvedMeetings, existingEntries);

	console.log(`Team: ${team.name} (${team.id})`);
	console.log(`User: ${user.username} (${user.id})`);
	if (dryRun) {
		console.log('Dry run: no ClickUp time entries will be changed');
	}

	for (const item of plan) {
		const names = item.meetings.map(meeting => meeting.name).join(', ');
		const taskIdentifiers = [
			...new Set(item.meetings.map(meeting => meeting.taskIdentifier)),
		].join(', ');
		const verb =
			item.action === 'unchanged'
				? 'unchanged'
				: dryRun
					? `would ${item.action}`
					: item.action;
		console.log(
			`${names}: ${verb} ${item.durationMs / 3_600_000}h on ${item.weekday} -> ${taskIdentifiers}`,
		);

		if (dryRun || item.action === 'unchanged') {
			continue;
		}
		if (item.action === 'create') {
			await createTimeEntry(team.id, user.id, item);
		} else {
			await updateTimeEntry(team.id, item);
		}
	}

	const created = plan.filter(item => item.action === 'create').length;
	const updated = plan.filter(item => item.action === 'update').length;
	const unchanged = plan.filter(item => item.action === 'unchanged').length;
	const prefix = dryRun ? 'Planned' : 'Completed';
	console.log(
		`${prefix}: ${created} create, ${updated} update, ${unchanged} unchanged`,
	);
}

if (import.meta.main) {
	try {
		await main();
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		console.error(`Failed to sync ClickUp weekly meetings: ${message}`);
		process.exit(1);
	}
}
