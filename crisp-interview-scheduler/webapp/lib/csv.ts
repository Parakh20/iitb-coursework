import Papa from "papaparse";
import type { Company, Student, TimeWindow } from "./types";

interface CompaniesParseResult {
  companies: Company[];
  errors: string[];
}

interface StudentsParseResult {
  students: Student[];
  errors: string[];
}

interface TimeWindowParseResult {
  window?: TimeWindow;
  error?: string;
}

const TIME_FORMAT_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;

function parseCsvRows(csvText: string): Record<string, string>[] {
  const result = Papa.parse<Record<string, string>>(csvText, {
    header: true,
    skipEmptyLines: true,
  });
  return result.data ?? [];
}

function parsePositiveInt(value: string | undefined, fieldName: string, rowLabel: string): {
  value?: number;
  error?: string;
} {
  if (value === undefined || value.trim() === "") {
    return { error: `${rowLabel}: missing required field "${fieldName}"` };
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) {
    return { error: `${rowLabel}: field "${fieldName}" must be a whole number, got "${value}"` };
  }
  if (parsed <= 0) {
    return { error: `${rowLabel}: field "${fieldName}" must be greater than zero, got ${parsed}` };
  }
  return { value: parsed };
}

function parseCompanyRow(row: Record<string, string>, index: number): {
  company?: Company;
  errors: string[];
} {
  const rowLabel = `Row ${index + 1}`;
  const errors: string[] = [];

  const name = row.name?.trim();
  if (!name) {
    errors.push(`${rowLabel}: missing required field "name"`);
  }

  const duration = parsePositiveInt(row.durationPerRound, "durationPerRound", rowLabel);
  if (duration.error) errors.push(duration.error);

  const numRounds = parsePositiveInt(row.numRounds, "numRounds", rowLabel);
  if (numRounds.error) errors.push(numRounds.error);

  const numPanels = parsePositiveInt(row.numPanels, "numPanels", rowLabel);
  if (numPanels.error) errors.push(numPanels.error);

  if (errors.length > 0 || !name) {
    return { errors };
  }

  return {
    company: {
      name,
      durationPerRound: duration.value as number,
      numRounds: numRounds.value as number,
      numPanels: numPanels.value as number,
    },
    errors: [],
  };
}

export function parseCompaniesCsv(csvText: string): CompaniesParseResult {
  try {
    const rows = parseCsvRows(csvText);
    const companies: Company[] = [];
    const errors: string[] = [];

    rows.forEach((row, index) => {
      const { company, errors: rowErrors } = parseCompanyRow(row, index);
      if (company) {
        companies.push(company);
      } else {
        errors.push(...rowErrors);
      }
    });

    return { companies, errors };
  } catch (caught: unknown) {
    const message = caught instanceof Error ? caught.message : "Unknown CSV parsing error";
    return { companies: [], errors: [`Failed to parse companies CSV: ${message}`] };
  }
}

function parseStudentRow(row: Record<string, string>, index: number): {
  student?: Student;
  errors: string[];
} {
  const rowLabel = `Row ${index + 1}`;
  const errors: string[] = [];

  const rollNumber = row.rollNumber?.trim();
  if (!rollNumber) {
    errors.push(`${rowLabel}: missing required field "rollNumber"`);
  }

  const shortlistRaw = row.shortlistedCompanies?.trim() ?? "";
  const shortlistedCompanies = shortlistRaw
    .split(";")
    .map((c) => c.trim())
    .filter((c) => c.length > 0);

  if (errors.length > 0 || !rollNumber) {
    return { errors };
  }

  const name = row.name?.trim();

  return {
    student: {
      rollNumber,
      ...(name ? { name } : {}),
      shortlistedCompanies,
    },
    errors: [],
  };
}

export function parseStudentsCsv(csvText: string): StudentsParseResult {
  try {
    const rows = parseCsvRows(csvText);
    const students: Student[] = [];
    const errors: string[] = [];

    rows.forEach((row, index) => {
      const { student, errors: rowErrors } = parseStudentRow(row, index);
      if (student) {
        students.push(student);
      } else {
        errors.push(...rowErrors);
      }
    });

    return { students, errors };
  } catch (caught: unknown) {
    const message = caught instanceof Error ? caught.message : "Unknown CSV parsing error";
    return { students: [], errors: [`Failed to parse students CSV: ${message}`] };
  }
}

function timeStringToMinutes(time: string): number | undefined {
  const match = TIME_FORMAT_REGEX.exec(time.trim());
  if (!match) return undefined;
  const hours = Number(match[1]);
  const minutes = Number(match[2]);
  return hours * 60 + minutes;
}

export function parseTimeWindow(start: string, end: string): TimeWindowParseResult {
  try {
    const startTime = timeStringToMinutes(start);
    if (startTime === undefined) {
      return { error: `Invalid start time format: "${start}", expected HH:mm (24-hour)` };
    }

    const endTime = timeStringToMinutes(end);
    if (endTime === undefined) {
      return { error: `Invalid end time format: "${end}", expected HH:mm (24-hour)` };
    }

    if (endTime <= startTime) {
      return { error: `End time "${end}" must be after start time "${start}"` };
    }

    return { window: { startTime, endTime } };
  } catch (caught: unknown) {
    const message = caught instanceof Error ? caught.message : "Unknown time parsing error";
    return { error: `Failed to parse time window: ${message}` };
  }
}
