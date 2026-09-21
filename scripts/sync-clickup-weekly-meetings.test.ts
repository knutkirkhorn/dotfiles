import {describe, expect, test} from 'bun:test';
import {
	applyDutyDayOff,
	buildSyncPlan,
	getCurrentWeekDates,
	hasDutyDayOffOnFriday,
	parseCliOptions,
	parseScheduleConfig,
	type TimeEntry,
} from './sync-clickup-weekly-meetings';

const NOW = new Date(2026, 8, 10, 8, 0, 0);

function makeEntry(overrides: Partial<TimeEntry> = {}): TimeEntry {
	return {
		id: 'entry-1',
		start: new Date(2026, 8, 7, 12, 0, 0).getTime().toString(),
		duration: (60 * 60 * 1000).toString(),
		description: '',
		task: {
			id: 'task-1',
			name: 'Project',
		},
		...overrides,
	};
}

describe('parseScheduleConfig', () => {
	test('parses a valid meeting mapping', () => {
		const config = parseScheduleConfig({
			meetings: [
				{
					name: 'Weekly planning',
					taskIdentifier: 'TASKID-1234',
					weekday: 'monday',
					durationMinutes: 60,
				},
			],
		});

		expect(config.meetings).toEqual([
			{
				name: 'Weekly planning',
				taskIdentifier: 'TASKID-1234',
				weekday: 'monday',
				durationMinutes: 60,
			},
		]);
		expect(config.dutyCalendar).toBeUndefined();
	});

	test('parses a duty calendar URL', () => {
		const config = parseScheduleConfig({
			dutyCalendar: {
				url: 'https://calendar.url.localhost/duty-day-off.ics',
				taskIdentifier: 'DAY-OFF-123',
				durationMinutes: 450,
			},
			meetings: [],
		});

		expect(config.dutyCalendar).toEqual({
			url: 'https://calendar.url.localhost/duty-day-off.ics',
			taskIdentifier: 'DAY-OFF-123',
			durationMinutes: 450,
		});
	});

	test('rejects invalid durations', () => {
		expect(() =>
			parseScheduleConfig({
				meetings: [
					{
						name: 'Weekly planning',
						taskIdentifier: 'TASKID-1234',
						weekday: 'monday',
						durationMinutes: 0,
					},
				],
			}),
		).toThrow('durationMinutes must be a positive integer');
	});

	test('rejects an invalid duty calendar URL', () => {
		expect(() =>
			parseScheduleConfig({
				dutyCalendar: {
					url: 'webcal://example.com/calendar',
					taskIdentifier: 'DAY-OFF-123',
					durationMinutes: 450,
				},
				meetings: [],
			}),
		).toThrow('must be a valid HTTPS URL');
	});
});

describe('applyDutyDayOff', () => {
	test('replaces Friday meetings with the configured day-off entry', () => {
		const result = applyDutyDayOff(
			[
				{
					name: 'Friday sync',
					taskIdentifier: 'SYNC-123',
					weekday: 'friday',
					durationMinutes: 30,
				},
				{
					name: 'Monday sync',
					taskIdentifier: 'SYNC-456',
					weekday: 'monday',
					durationMinutes: 30,
				},
			],
			{
				url: 'https://calendar.url.localhost/duty-day-off.ics',
				taskIdentifier: 'DAY-OFF-123',
				durationMinutes: 450,
			},
		);

		expect(result.skippedFridayMeetingCount).toBe(1);
		expect(result.meetings).toContainEqual({
			name: 'Day off due to duty last weekend',
			taskIdentifier: 'DAY-OFF-123',
			weekday: 'friday',
			durationMinutes: 450,
		});
		expect(
			result.meetings.some(meeting => meeting.name === 'Friday sync'),
		).toBe(false);
	});
});

describe('getCurrentWeekDates', () => {
	test('returns the full local Monday-to-Sunday week', () => {
		const dates = getCurrentWeekDates(NOW);

		expect(dates.get('monday')?.getDate()).toBe(7);
		expect(dates.get('sunday')?.getDate()).toBe(13);
		expect(dates.get('monday')?.getHours()).toBe(12);
	});
});

describe('parseCliOptions', () => {
	test('accepts a target date for a dry run', () => {
		const options = parseCliOptions(['--dry-run', '--date', '2026-09-14']);

		expect(options.dryRun).toBe(true);
		expect(options.referenceDate.getFullYear()).toBe(2026);
		expect(options.referenceDate.getMonth()).toBe(8);
		expect(options.referenceDate.getDate()).toBe(14);
	});

	test('rejects a target date without dry-run', () => {
		expect(() => parseCliOptions(['--date', '2026-09-14'])).toThrow(
			'--date can only be used with --dry-run',
		);
	});

	test('rejects an invalid target date', () => {
		expect(() =>
			parseCliOptions(['--dry-run', '--date', '2026-02-30']),
		).toThrow('--date must be a valid calendar date');
	});
});

describe('hasDutyDayOffOnFriday', () => {
	test('finds a day-off event on Friday in the current week', () => {
		const calendar = [
			'BEGIN:VCALENDAR',
			'BEGIN:VEVENT',
			'DTSTART;VALUE=DATE:20260911',
			'DTEND;VALUE=DATE:20260912',
			'SUMMARY:Day off due to duty last weekend',
			'END:VEVENT',
			'END:VCALENDAR',
		].join('\r\n');

		expect(hasDutyDayOffOnFriday(calendar, NOW)).toBe(true);
	});

	test('ignores day-off events on another Friday', () => {
		const calendar = [
			'BEGIN:VCALENDAR',
			'BEGIN:VEVENT',
			'DTSTART;VALUE=DATE:20260918',
			'SUMMARY:Day off due to duty last weekend',
			'END:VEVENT',
			'END:VCALENDAR',
		].join('\r\n');

		expect(hasDutyDayOffOnFriday(calendar, NOW)).toBe(false);
	});
});

describe('buildSyncPlan', () => {
	const meeting = {
		name: 'Weekly planning',
		taskIdentifier: 'TASKID-1234',
		taskId: 'task-1',
		weekday: 'monday' as const,
		durationMinutes: 60,
	};

	test('creates an entry when the meeting is not logged', () => {
		const plan = buildSyncPlan([meeting], [], NOW);

		expect(plan).toHaveLength(1);
		expect(plan[0]?.action).toBe('create');
		expect(plan[0]?.start.getDate()).toBe(7);
		expect(plan[0]?.durationMs).toBe(3_600_000);
	});

	test('leaves a matching task and day entry unchanged', () => {
		const plan = buildSyncPlan([meeting], [makeEntry()], NOW);

		expect(plan[0]?.action).toBe('unchanged');
	});

	test('matches an existing entry at a different time on the same day', () => {
		const morningEntry = makeEntry({
			start: new Date(2026, 8, 7, 8, 0, 0).getTime().toString(),
		});

		const plan = buildSyncPlan([meeting], [morningEntry], NOW);

		expect(plan[0]?.action).toBe('unchanged');
	});

	test('updates the matching task and day when duration changes', () => {
		const unrelatedEntry = makeEntry({
			id: 'entry-unrelated',
			start: new Date(2026, 8, 8, 12, 0, 0).getTime().toString(),
		});
		const managedEntry = makeEntry({
			duration: (30 * 60 * 1000).toString(),
		});

		const plan = buildSyncPlan([meeting], [unrelatedEntry, managedEntry], NOW);

		expect(plan[0]?.action).toBe('update');
		expect(plan[0]?.existingEntry?.id).toBe('entry-1');
	});

	test('combines meetings mapped to the same task and day', () => {
		const secondMeeting = {
			...meeting,
			name: 'Customer sync',
			durationMinutes: 30,
		};

		const plan = buildSyncPlan([meeting, secondMeeting], [], NOW);

		expect(plan).toHaveLength(1);
		expect(plan[0]?.meetings).toHaveLength(2);
		expect(plan[0]?.durationMs).toBe(90 * 60 * 1000);
	});
});
