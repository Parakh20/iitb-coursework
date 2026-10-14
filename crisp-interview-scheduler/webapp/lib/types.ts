export interface Company {
  name: string;
  durationPerRound: number; // minutes
  numRounds: number;
  numPanels: number;
}

export interface Student {
  rollNumber: string;
  name?: string;
  shortlistedCompanies: string[];
}

export interface TimeWindow {
  startTime: number; // minutes from midnight
  endTime: number;
}

export interface Interview {
  studentId: string;
  companyName: string;
  round: number;
  startTime: number;
  endTime: number;
  panelId: number; // 0-based
}

export interface Conflict {
  studentId: string;
  companyName: string;
  round?: number;
  reason: string;
}

export interface ScheduleInput {
  students: Student[];
  companies: Company[];
  slot: TimeWindow;
  /** scheduling granularity in minutes; defaults to 5 */
  slotGranularity?: number;
}

export interface ScheduleResult {
  schedule: Interview[];
  conflicts: Conflict[];
}
