import { describe, it, expect } from "vitest";
import { generateSchedule } from "./scheduler";
import type { ScheduleInput } from "./types";

const nineAM = 9 * 60;
const tenAM = 10 * 60;
const elevenAM = 11 * 60;
const noon = 12 * 60;

describe("generateSchedule - TC1 basic scheduling", () => {
  it("schedules two students for different companies with no conflicts", () => {
    const input: ScheduleInput = {
      slot: { startTime: nineAM, endTime: elevenAM },
      companies: [
        { name: "CompanyA", durationPerRound: 30, numRounds: 2, numPanels: 2 },
        { name: "CompanyB", durationPerRound: 45, numRounds: 1, numPanels: 1 },
      ],
      students: [
        { rollNumber: "S1", shortlistedCompanies: ["CompanyA", "CompanyB"] },
        { rollNumber: "S2", shortlistedCompanies: ["CompanyA"] },
      ],
    };

    const result = generateSchedule(input);

    expect(result.conflicts).toHaveLength(0);
    expect(result.schedule.length).toBe(5);

    for (const student of ["S1", "S2"]) {
      const interviews = result.schedule
        .filter((i) => i.studentId === student)
        .sort((a, b) => a.startTime - b.startTime);
      for (let i = 1; i < interviews.length; i++) {
        expect(interviews[i].startTime).toBeGreaterThanOrEqual(interviews[i - 1].endTime);
      }
    }
  });
});

describe("generateSchedule - TC2 panel limitation", () => {
  it("schedules only as many simultaneous students as there are panels", () => {
    const input: ScheduleInput = {
      slot: { startTime: nineAM, endTime: tenAM },
      companies: [{ name: "CompanyA", durationPerRound: 30, numRounds: 1, numPanels: 2 }],
      students: [
        { rollNumber: "S1", shortlistedCompanies: ["CompanyA"] },
        { rollNumber: "S2", shortlistedCompanies: ["CompanyA"] },
        { rollNumber: "S3", shortlistedCompanies: ["CompanyA"] },
      ],
    };

    const result = generateSchedule(input);

    expect(result.conflicts).toHaveLength(0);
    expect(result.schedule).toHaveLength(3);

    const atNineAM = result.schedule.filter((i) => i.startTime === nineAM);
    expect(atNineAM).toHaveLength(2);

    const third = result.schedule.find((i) => i.startTime === nineAM + 30);
    expect(third).toBeDefined();
  });
});

describe("generateSchedule - TC3 conflict detection", () => {
  it("flags a conflict when a student's interviews cannot all fit in the slot", () => {
    const input: ScheduleInput = {
      slot: { startTime: nineAM, endTime: elevenAM },
      companies: [
        { name: "CompanyA", durationPerRound: 60, numRounds: 1, numPanels: 1 },
        { name: "CompanyB", durationPerRound: 60, numRounds: 1, numPanels: 1 },
        { name: "CompanyC", durationPerRound: 60, numRounds: 1, numPanels: 1 },
      ],
      students: [
        { rollNumber: "S1", shortlistedCompanies: ["CompanyA", "CompanyB", "CompanyC"] },
      ],
    };

    const result = generateSchedule(input);

    expect(result.conflicts.length).toBeGreaterThan(0);
    expect(result.schedule.length).toBe(2);
  });
});

describe("generateSchedule - round precedence", () => {
  it("never schedules round 2 before round 1 for the same student/company", () => {
    const input: ScheduleInput = {
      slot: { startTime: nineAM, endTime: noon },
      companies: [{ name: "CompanyA", durationPerRound: 30, numRounds: 3, numPanels: 1 }],
      students: [{ rollNumber: "S1", shortlistedCompanies: ["CompanyA"] }],
    };

    const result = generateSchedule(input);
    const rounds = result.schedule
      .filter((i) => i.studentId === "S1" && i.companyName === "CompanyA")
      .sort((a, b) => a.round - b.round);

    expect(rounds).toHaveLength(3);
    for (let i = 1; i < rounds.length; i++) {
      expect(rounds[i].round).toBe(rounds[i - 1].round + 1);
      expect(rounds[i].startTime).toBeGreaterThanOrEqual(rounds[i - 1].endTime);
    }
  });
});

describe("generateSchedule - student overlap", () => {
  it("never overlaps two interviews for the same student even across companies", () => {
    const input: ScheduleInput = {
      slot: { startTime: nineAM, endTime: elevenAM },
      companies: [
        { name: "CompanyA", durationPerRound: 30, numRounds: 1, numPanels: 3 },
        { name: "CompanyB", durationPerRound: 30, numRounds: 1, numPanels: 3 },
      ],
      students: [{ rollNumber: "S1", shortlistedCompanies: ["CompanyA", "CompanyB"] }],
    };

    const result = generateSchedule(input);
    const interviews = result.schedule
      .filter((i) => i.studentId === "S1")
      .sort((a, b) => a.startTime - b.startTime);

    expect(interviews).toHaveLength(2);
    expect(interviews[1].startTime).toBeGreaterThanOrEqual(interviews[0].endTime);
  });
});

describe("generateSchedule - panel capacity conflict", () => {
  it("reports a conflict when more students need a slot than panels can support within the window", () => {
    const input: ScheduleInput = {
      slot: { startTime: nineAM, endTime: nineAM + 30 },
      companies: [{ name: "CompanyA", durationPerRound: 30, numRounds: 1, numPanels: 1 }],
      students: [
        { rollNumber: "S1", shortlistedCompanies: ["CompanyA"] },
        { rollNumber: "S2", shortlistedCompanies: ["CompanyA"] },
      ],
    };

    const result = generateSchedule(input);
    expect(result.schedule).toHaveLength(1);
    expect(result.conflicts).toHaveLength(1);
    expect(result.conflicts[0].companyName).toBe("CompanyA");
  });
});
