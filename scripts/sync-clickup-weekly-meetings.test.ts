import {describe, expect, test} from 'bun:test';
import {
	buildSyncPlan,
	getCurrentWeekDates,
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
});

describe('getCurrentWeekDates', () => {
	test('returns the full local Monday-to-Sunday week', () => {
		const dates = getCurrentWeekDates(NOW);

		expect(dates.get('monday')?.getDate()).toBe(7);
		expect(dates.get('sunday')?.getDate()).toBe(13);
		expect(dates.get('monday')?.getHours()).toBe(12);
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
