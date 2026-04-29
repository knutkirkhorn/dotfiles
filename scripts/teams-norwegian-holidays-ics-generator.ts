#!/usr/bin/env bun
import {mkdir, writeFile} from 'node:fs/promises';
import {dirname} from 'node:path';
import process from 'node:process';
import Holidays, {type HolidaysTypes} from 'date-holidays';

const DEFAULT_HOLIDAY_TIME_ZONE = 'Europe/Oslo';
const DEFAULT_SUBJECT_PREFIX = 'Out of office';
const SCRIPT_PATH = 'scripts/teams-norwegian-holidays-ics-generator.ts';

interface CliOptions {
	holidayTimeZone: string;
	icsPath?: string;
	subjectPrefix: string;
	year: number;
}

interface HolidayDay {
	date: string;
	names: string[];
}

function parseArgs(argv: string[]): CliOptions {
	const now = new Date();
	const options: CliOptions = {
		holidayTimeZone: process.env.HOLIDAY_TIME_ZONE ?? DEFAULT_HOLIDAY_TIME_ZONE,
		subjectPrefix:
			process.env.TEAMS_OUT_OF_OFFICE_SUBJECT_PREFIX ?? DEFAULT_SUBJECT_PREFIX,
		year: now.getFullYear(),
	};

	for (let index = 0; index < argv.length; index++) {
		const arg = argv[index];
		const next = argv[index + 1];

		switch (arg) {
			case '--ics':
				if (!next) throw new Error('Missing value for --ics');
				options.icsPath = next;
				index++;
				break;
			case '--year':
				if (!next) throw new Error('Missing value for --year');
				options.year = parseYear(next);
				index++;
				break;
			case '--holiday-timezone':
				if (!next) throw new Error('Missing value for --holiday-timezone');
				options.holidayTimeZone = next;
				index++;
				break;
			case '--subject-prefix':
				if (!next) throw new Error('Missing value for --subject-prefix');
				options.subjectPrefix = next;
				index++;
				break;
			case '--help':
			case '-h':
				printHelp();
				process.exit(0);
			default:
				throw new Error(`Unknown argument: ${arg}`);
		}
	}

	return options;
}

function parseYear(value: string): number {
	const year = Number.parseInt(value, 10);
	if (!Number.isInteger(year) || year < 1900 || year > 2100) {
		throw new Error(`Invalid year: ${value}`);
	}
	return year;
}

function printHelp() {
	console.log(`Create an ICS file with Norwegian public holidays as out-of-office events.

Usage:
  bun run ${SCRIPT_PATH} [options]

Options:
  --ics <path>               Write an importable .ics calendar file
  --year <year>              Holiday year. Defaults to current year
  --holiday-timezone <zone>  date-holidays timezone. Defaults to Europe/Oslo
  --subject-prefix <text>    Calendar event subject prefix. Defaults to "Out of office"

Environment:
  HOLIDAY_TIME_ZONE          Optional date-holidays timezone override
  TEAMS_OUT_OF_OFFICE_SUBJECT_PREFIX   Optional event subject prefix
`);
}

function getNorwegianPublicHolidays(
	year: number,
	timeZone: string,
): HolidayDay[] {
	const holidays = new Holidays('NO', {
		languages: ['no', 'en'],
		timezone: timeZone,
		types: ['public'],
	});

	const byDate = new Map<string, Set<string>>();
	for (const holiday of holidays.getHolidays(year, 'no')) {
		if (holiday.type !== 'public') continue;
		const date = getHolidayDate(holiday);
		let names = byDate.get(date);
		if (!names) {
			names = new Set<string>();
			byDate.set(date, names);
		}
		names.add(holiday.name);
	}

	return [...byDate.entries()]
		.map(([date, names]) => ({
			date,
			names: [...names].sort((first, second) =>
				first.localeCompare(second, 'no'),
			),
		}))
		.sort((first, second) => first.date.localeCompare(second.date));
}

function getHolidayDate(holiday: HolidaysTypes.Holiday): string {
	return holiday.date.slice(0, 10);
}

function addDays(date: string, days: number): string {
	const value = new Date(`${date}T00:00:00.000Z`);
	value.setUTCDate(value.getUTCDate() + days);
	return value.toISOString().slice(0, 10);
}

function buildSubject(holiday: HolidayDay, subjectPrefix: string): string {
	return `${subjectPrefix}: ${holiday.names.join(' / ')}`;
}

async function writeIcsFile(
	holidays: HolidayDay[],
	options: CliOptions,
	path: string,
): Promise<void> {
	await mkdir(dirname(path), {recursive: true});
	await writeFile(path, buildIcsCalendar(holidays, options), 'utf8');
}

function buildIcsCalendar(holidays: HolidayDay[], options: CliOptions): string {
	const lines = [
		'BEGIN:VCALENDAR',
		'VERSION:2.0',
		'PRODID:-//dotfiles//Norwegian Holidays Out Of Office//EN',
		'CALSCALE:GREGORIAN',
		'METHOD:PUBLISH',
	];

	for (const holiday of holidays) {
		lines.push(...buildIcsEvent(holiday, options));
	}

	lines.push('END:VCALENDAR');
	return `${lines.map(foldIcsLine).join('\r\n')}\r\n`;
}

function buildIcsEvent(holiday: HolidayDay, options: CliOptions): string[] {
	const subject = buildSubject(holiday, options.subjectPrefix);
	const description = `Created by dotfiles ${SCRIPT_PATH}`;

	return [
		'BEGIN:VEVENT',
		`UID:dotfiles-norwegian-holiday-out-of-office-${holiday.date}@knutkirkhorn.com`,
		`DTSTAMP:${formatIcsTimestamp(new Date())}`,
		`DTSTART;VALUE=DATE:${formatIcsDate(holiday.date)}`,
		`DTEND;VALUE=DATE:${formatIcsDate(addDays(holiday.date, 1))}`,
		`SUMMARY:${escapeIcsText(subject)}`,
		`DESCRIPTION:${escapeIcsText(description)}`,
		'TRANSP:OPAQUE',
		'STATUS:CONFIRMED',
		'X-MICROSOFT-CDO-ALLDAYEVENT:TRUE',
		'X-MICROSOFT-CDO-BUSYSTATUS:OOF',
		'END:VEVENT',
	];
}

function formatIcsDate(date: string): string {
	return date.replaceAll('-', '');
}

function formatIcsTimestamp(date: Date): string {
	return date
		.toISOString()
		.replaceAll('-', '')
		.replaceAll(':', '')
		.replace(/\.\d{3}Z$/, 'Z');
}

function escapeIcsText(value: string): string {
	return value
		.replaceAll('\\', '\\\\')
		.replaceAll(';', '\\;')
		.replaceAll(',', '\\,')
		.replaceAll('\n', '\\n');
}

function foldIcsLine(line: string): string {
	const maxLength = 75;
	if (line.length <= maxLength) return line;

	const chunks: string[] = [];
	let rest = line;
	while (rest.length > maxLength) {
		chunks.push(rest.slice(0, maxLength));
		rest = rest.slice(maxLength);
	}
	chunks.push(rest);
	return chunks.join('\r\n ');
}

function printPlan(holidays: HolidayDay[], options: CliOptions): void {
	console.log(`Norwegian public holidays for ${options.year}:`);
	for (const holiday of holidays) {
		console.log(
			`- ${holiday.date}: ${buildSubject(holiday, options.subjectPrefix)}`,
		);
	}
}

function printImportInstructions(path: string): void {
	console.log(`\nWrote ICS file: ${path}`);
	console.log(
		'Import it by dragging and dropping the .ics file into Teams, then select the regular calendar to import it into your calendar.',
	);
}

async function main() {
	const options = parseArgs(process.argv.slice(2));
	const holidays = getNorwegianPublicHolidays(
		options.year,
		options.holidayTimeZone,
	);

	printPlan(holidays, options);

	if (!options.icsPath) {
		console.log('\nPass --ics <path> to write an importable calendar file.');
		return;
	}

	await writeIcsFile(holidays, options, options.icsPath);
	printImportInstructions(options.icsPath);
}

if (import.meta.main) {
	try {
		await main();
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		console.error(`Failed to create Norwegian holiday ICS file: ${message}`);
		process.exit(1);
	}
}
