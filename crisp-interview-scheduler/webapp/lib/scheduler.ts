import type {
  Company,
  Conflict,
  Interview,
  ScheduleInput,
  ScheduleResult,
  Student,
  TimeWindow,
} from "./types";

const DEFAULT_GRANULARITY_MINUTES = 5;

interface SchedulerState {
  slot: TimeWindow;
  granularity: number;
  companies: Map<string, Company>;
  /** companyName -> panelId -> set of busy slot indices */
  panelBusy: Map<string, Set<number>[]>;
  /** studentId -> list of [startTime, endTime) busy intervals */
  studentBusy: Map<string, Array<[number, number]>>;
}

function buildState(input: ScheduleInput): SchedulerState {
  const granularity = input.slotGranularity ?? DEFAULT_GRANULARITY_MINUTES;
  const companies = new Map<string, Company>();
  const panelBusy = new Map<string, Set<number>[]>();

  for (const company of input.companies) {
    companies.set(company.name, company);
    const panels: Set<number>[] = [];
    for (let i = 0; i < company.numPanels; i++) {
      panels.push(new Set<number>());
    }
    panelBusy.set(company.name, panels);
  }

  const studentBusy = new Map<string, Array<[number, number]>>();
  for (const student of input.students) {
    studentBusy.set(student.rollNumber, []);
  }

  return { slot: input.slot, granularity, companies, panelBusy, studentBusy };
}

function timeToSlotIndex(state: SchedulerState, minutes: number): number {
  return Math.round((minutes - state.slot.startTime) / state.granularity);
}

function isStudentAvailable(
  state: SchedulerState,
  studentId: string,
  startTime: number,
  endTime: number
): boolean {
  const busyIntervals = state.studentBusy.get(studentId) ?? [];
  for (const [busyStart, busyEnd] of busyIntervals) {
    if (startTime < busyEnd && endTime > busyStart) {
      return false;
    }
  }
  return true;
}

function isPanelAvailable(
  state: SchedulerState,
  companyName: string,
  panelId: number,
  startTime: number,
  endTime: number
): boolean {
  const startSlot = timeToSlotIndex(state, startTime);
  const endSlot = timeToSlotIndex(state, endTime);
  const busySlots = state.panelBusy.get(companyName)?.[panelId];
  if (!busySlots) return false;
  for (let i = startSlot; i < endSlot; i++) {
    if (busySlots.has(i)) return false;
  }
  return true;
}

function reservePanel(
  state: SchedulerState,
  companyName: string,
  panelId: number,
  startTime: number,
  endTime: number
): void {
  const startSlot = timeToSlotIndex(state, startTime);
  const endSlot = timeToSlotIndex(state, endTime);
  const busySlots = state.panelBusy.get(companyName)?.[panelId];
  if (!busySlots) return;
  for (let i = startSlot; i < endSlot; i++) {
    busySlots.add(i);
  }
}

function releasePanel(
  state: SchedulerState,
  companyName: string,
  panelId: number,
  startTime: number,
  endTime: number
): void {
  const startSlot = timeToSlotIndex(state, startTime);
  const endSlot = timeToSlotIndex(state, endTime);
  const busySlots = state.panelBusy.get(companyName)?.[panelId];
  if (!busySlots) return;
  for (let i = startSlot; i < endSlot; i++) {
    busySlots.delete(i);
  }
}

function findAvailablePanel(
  state: SchedulerState,
  companyName: string,
  startTime: number,
  endTime: number
): number {
  const company = state.companies.get(companyName);
  if (!company) return -1;
  for (let panelId = 0; panelId < company.numPanels; panelId++) {
    if (isPanelAvailable(state, companyName, panelId, startTime, endTime)) {
      return panelId;
    }
  }
  return -1;
}

/**
 * Attempts to schedule every round of a single company for a student,
 * starting the search from `cursorStart`. On success returns the list of
 * interviews and the new cursor (end of the last scheduled round). On
 * failure returns a conflict reason and rolls back any partial panel/student
 * reservations made for this company.
 */
function scheduleCompanyForStudent(
  state: SchedulerState,
  studentId: string,
  company: Company,
  cursorStart: number
): { interviews: Interview[]; cursorEnd: number } | { conflict: string; round: number } {
  const interviews: Interview[] = [];
  const studentBusy = state.studentBusy.get(studentId);
  if (!studentBusy) {
    return { conflict: "Unknown student", round: 1 };
  }

  let cursor = cursorStart;

  for (let round = 1; round <= company.numRounds; round++) {
    let scheduled = false;

    for (
      let startTime = cursor;
      startTime + company.durationPerRound <= state.slot.endTime;
      startTime += state.granularity
    ) {
      const endTime = startTime + company.durationPerRound;

      if (!isStudentAvailable(state, studentId, startTime, endTime)) continue;

      const panelId = findAvailablePanel(state, company.name, startTime, endTime);
      if (panelId === -1) continue;

      reservePanel(state, company.name, panelId, startTime, endTime);
      studentBusy.push([startTime, endTime]);
      interviews.push({
        studentId,
        companyName: company.name,
        round,
        startTime,
        endTime,
        panelId,
      });

      cursor = endTime;
      scheduled = true;
      break;
    }

    if (!scheduled) {
      // Roll back everything reserved for this company so far.
      for (const interview of interviews) {
        releasePanel(
          state,
          interview.companyName,
          interview.panelId,
          interview.startTime,
          interview.endTime
        );
      }
      studentBusy.splice(studentBusy.length - interviews.length, interviews.length);

      return {
        conflict: `Cannot schedule company ${company.name} round ${round} for student ${studentId}: no available panel/time slot within the window`,
        round,
      };
    }
  }

  return { interviews, cursorEnd: cursor };
}

function scheduleStudent(
  state: SchedulerState,
  student: Student,
  conflicts: Conflict[]
): Interview[] {
  const result: Interview[] = [];
  let cursor = state.slot.startTime;

  for (const companyName of student.shortlistedCompanies) {
    const company = state.companies.get(companyName);
    if (!company) {
      conflicts.push({
        studentId: student.rollNumber,
        companyName,
        reason: `Unknown company ${companyName} in shortlist`,
      });
      continue;
    }

    const outcome = scheduleCompanyForStudent(state, student.rollNumber, company, cursor);

    if ("conflict" in outcome) {
      conflicts.push({
        studentId: student.rollNumber,
        companyName,
        round: outcome.round,
        reason: outcome.conflict,
      });
      continue;
    }

    result.push(...outcome.interviews);
    cursor = outcome.cursorEnd;
  }

  return result;
}

export function generateSchedule(input: ScheduleInput): ScheduleResult {
  const state = buildState(input);
  const conflicts: Conflict[] = [];
  const schedule: Interview[] = [];

  const orderedStudents = [...input.students].sort(
    (a, b) => a.shortlistedCompanies.length - b.shortlistedCompanies.length
  );

  for (const student of orderedStudents) {
    const interviews = scheduleStudent(state, student, conflicts);
    schedule.push(...interviews);
  }

  return { schedule, conflicts };
}
