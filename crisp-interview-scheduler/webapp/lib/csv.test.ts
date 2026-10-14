import { describe, it, expect } from "vitest";
import { parseCompaniesCsv, parseStudentsCsv, parseTimeWindow } from "./csv";

describe("parseCompaniesCsv", () => {
  it("parses a valid companies CSV", () => {
    const csv =
      "name,durationPerRound,numRounds,numPanels\n" +
      "CompanyA,30,2,2\n" +
      "CompanyB,45,1,1\n";

    const { companies, errors } = parseCompaniesCsv(csv);

    expect(errors).toHaveLength(0);
    expect(companies).toHaveLength(2);
    expect(companies[0]).toEqual({
      name: "CompanyA",
      durationPerRound: 30,
      numRounds: 2,
      numPanels: 2,
    });
  });

  it("reports an error for a missing required field", () => {
    const csv = "name,durationPerRound,numRounds,numPanels\n,30,2,2\n";

    const { companies, errors } = parseCompaniesCsv(csv);

    expect(companies).toHaveLength(0);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0]).toMatch(/name/i);
  });

  it("reports an error for negative or zero duration", () => {
    const csv = "name,durationPerRound,numRounds,numPanels\nCompanyA,0,2,2\n";

    const { companies, errors } = parseCompaniesCsv(csv);

    expect(companies).toHaveLength(0);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0]).toMatch(/duration/i);
  });

  it("reports an error for negative numRounds", () => {
    const csv = "name,durationPerRound,numRounds,numPanels\nCompanyA,30,-1,2\n";

    const { companies, errors } = parseCompaniesCsv(csv);

    expect(companies).toHaveLength(0);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0]).toMatch(/numRounds/i);
  });

  it("reports an error for zero numPanels", () => {
    const csv = "name,durationPerRound,numRounds,numPanels\nCompanyA,30,2,0\n";

    const { companies, errors } = parseCompaniesCsv(csv);

    expect(companies).toHaveLength(0);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0]).toMatch(/numPanels/i);
  });

  it("never throws on malformed CSV input", () => {
    expect(() => parseCompaniesCsv("not,a,valid\nheader at all")).not.toThrow();
  });
});

describe("parseStudentsCsv", () => {
  it("parses a valid students CSV with semicolon-separated shortlist", () => {
    const csv =
      "rollNumber,name,shortlistedCompanies\n" +
      "S1,Alice,CompanyA;CompanyB\n" +
      "S2,Bob,CompanyA\n";

    const { students, errors } = parseStudentsCsv(csv);

    expect(errors).toHaveLength(0);
    expect(students).toHaveLength(2);
    expect(students[0]).toEqual({
      rollNumber: "S1",
      name: "Alice",
      shortlistedCompanies: ["CompanyA", "CompanyB"],
    });
    expect(students[1].shortlistedCompanies).toEqual(["CompanyA"]);
  });

  it("reports an error for a missing rollNumber", () => {
    const csv = "rollNumber,name,shortlistedCompanies\n,Alice,CompanyA\n";

    const { students, errors } = parseStudentsCsv(csv);

    expect(students).toHaveLength(0);
    expect(errors.length).toBeGreaterThan(0);
    expect(errors[0]).toMatch(/rollNumber/i);
  });

  it("never throws on malformed CSV input", () => {
    expect(() => parseStudentsCsv("garbage\ndata,here")).not.toThrow();
  });
});

describe("parseTimeWindow", () => {
  it("parses valid 24-hour start/end times", () => {
    const { window, error } = parseTimeWindow("09:00", "18:00");

    expect(error).toBeUndefined();
    expect(window).toEqual({ startTime: 9 * 60, endTime: 18 * 60 });
  });

  it("reports an error when end time is before start time", () => {
    const { window, error } = parseTimeWindow("18:00", "09:00");

    expect(window).toBeUndefined();
    expect(error).toMatch(/end/i);
  });

  it("reports an error when end time equals start time", () => {
    const { window, error } = parseTimeWindow("09:00", "09:00");

    expect(window).toBeUndefined();
    expect(error).toMatch(/end/i);
  });

  it("reports an error for malformed time format", () => {
    const { window, error } = parseTimeWindow("9am", "18:00");

    expect(window).toBeUndefined();
    expect(error).toMatch(/format/i);
  });

  it("never throws on garbage input", () => {
    expect(() => parseTimeWindow("", "")).not.toThrow();
  });
});
