#!/usr/bin/env bun

export {};

declare const process: {
	env: Record<string, string | undefined>;
	argv: string[];
	exit(code?: number): never;
};

const CLICKUP_API_BASE = "https://api.clickup.com/api/v2";
const ENTRY_DURATION_MS = 30 * 60 * 1000;
const ENTRY_START_HOUR = 9;
const ENTRY_START_MINUTE = 0;

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

interface TimeEntry {
	id: string;
	start: string;
	duration: string;
	task: {
		id: string;
		name: string;
	} | null;
}

interface TimeEntriesResponse {
	data: TimeEntry[];
}

function getApiKey(): string {
	const apiKey = process.env.CLICKUP_API_KEY;
	if (!apiKey) {
		console.error("Missing CLICKUP_API_KEY in environment");
		process.exit(1);
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
			"Content-Type": "application/json",
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
	const response = await clickupRequest<{ user: ClickUpUser }>("/user");
	return response.user;
}

async function getTeams(): Promise<Team[]> {
	const response = await clickupRequest<{ teams: Team[] }>("/team");
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

function getCurrentWeekDays(): Date[] {
	const now = new Date();
	const dayOfWeek = now.getDay();
	const daysToMonday = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
	const monday = new Date(now);
	monday.setDate(now.getDate() - daysToMonday);
	monday.setHours(0, 0, 0, 0);

	const days: Date[] = [];
	// Add time for monday (0) to friday (4)
	for (let i = 0; i < 5; i++) {
		const date = new Date(monday);
		date.setDate(monday.getDate() + i);
		days.push(date);
	}
	return days;
}

function getDateKey(value: Date): string {
	const year = value.getFullYear();
	const month = String(value.getMonth() + 1).padStart(2, "0");
	const day = String(value.getDate()).padStart(2, "0");
	return `${year}-${month}-${day}`;
}

async function getWeekEntries(
	teamId: string,
	userId: number,
): Promise<TimeEntry[]> {
	const weekDays = getCurrentWeekDays();
	const start = new Date(weekDays[0]);
	const end = new Date(weekDays[weekDays.length - 1]);
	start.setHours(0, 0, 0, 0);
	end.setHours(23, 59, 59, 999);

	const response = await clickupRequest<TimeEntriesResponse>(
		`/team/${teamId}/time_entries?start_date=${start.getTime()}&end_date=${end.getTime()}&assignee=${userId}`,
	);
	return response.data ?? [];
}

function matchesTaskEntry(entry: TimeEntry, taskId: string): boolean {
	return (
		entry.task?.id === taskId &&
		parseInt(entry.duration, 10) === ENTRY_DURATION_MS
	);
}

async function createTimeEntry(
	teamId: string,
	taskId: string,
	userId: number,
	start: Date,
): Promise<void> {
	await clickupRequest(`/team/${teamId}/time_entries`, {
		method: "POST",
		body: JSON.stringify({
			start: start.getTime().toString(),
			duration: ENTRY_DURATION_MS.toString(),
			assignee: userId,
			billable: false,
			tid: taskId,
		}),
	});
}

async function main() {
	const taskIdentifier = process.argv[2] ?? process.env.CLICKUP_TASK_IDENTIFIER;
	const teamIdFromEnv = process.env.CLICKUP_TEAM_ID;

	if (!taskIdentifier) {
		throw new Error(
			"Missing task id. Set CLICKUP_TASK_IDENTIFIER in .env or pass a task id as the first argument",
		);
	}

	const [user, teams] = await Promise.all([getAuthorizedUser(), getTeams()]);
	if (teams.length === 0) {
		throw new Error("No ClickUp teams available for current account");
	}

	const team = teamIdFromEnv
		? teams.find((item) => item.id === teamIdFromEnv)
		: teams[0];

	if (!team) {
		throw new Error(`Could not find team for CLICKUP_TEAM_ID=${teamIdFromEnv}`);
	}

	const taskId = await resolveTaskId(taskIdentifier, team.id);
	const existingEntries = await getWeekEntries(team.id, user.id);
	const existingTaskDays = new Set<string>();

	for (const entry of existingEntries) {
		if (!matchesTaskEntry(entry, taskId)) continue;
		const startDate = new Date(Number.parseInt(entry.start, 10));
		existingTaskDays.add(getDateKey(startDate));
	}

	const weekDays = getCurrentWeekDays();
	let createdCount = 0;
	let skippedCount = 0;

	for (const weekDay of weekDays) {
		const entryDate = new Date(weekDay);
		entryDate.setHours(ENTRY_START_HOUR, ENTRY_START_MINUTE, 0, 0);
		const dayKey = getDateKey(entryDate);

		if (existingTaskDays.has(dayKey)) {
			skippedCount++;
			continue;
		}

		await createTimeEntry(team.id, taskId, user.id, entryDate);
		createdCount++;
	}

	console.log(`Team: ${team.name} (${team.id})`);
	console.log(`User: ${user.username} (${user.id})`);
	console.log(`Task: ${taskIdentifier} -> ${taskId}`);
	console.log(
		`Created ${createdCount} entries, skipped ${skippedCount} existing`,
	);
}

try {
	await main();
} catch (error) {
	const message = error instanceof Error ? error.message : String(error);
	console.error(`Failed to initialize ClickUp week: ${message}`);
	process.exit(1);
}
