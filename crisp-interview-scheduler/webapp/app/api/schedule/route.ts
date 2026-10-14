import { parseCompaniesCsv, parseStudentsCsv, parseTimeWindow } from "@/lib/csv";
import { generateSchedule } from "@/lib/scheduler";

function badRequest(message: string): Response {
  return Response.json({ error: message }, { status: 400 });
}

async function readTextField(formData: FormData, fieldName: string): Promise<string | undefined> {
  const value = formData.get(fieldName);
  if (value instanceof File) {
    return await value.text();
  }
  if (typeof value === "string") {
    return value;
  }
  return undefined;
}

export async function POST(request: Request): Promise<Response> {
  try {
    const formData = await request.formData();

    const companiesCsv = await readTextField(formData, "companies");
    const studentsCsv = await readTextField(formData, "students");
    const startTime = await readTextField(formData, "startTime");
    const endTime = await readTextField(formData, "endTime");

    if (!companiesCsv) return badRequest('Missing required file field "companies"');
    if (!studentsCsv) return badRequest('Missing required file field "students"');
    if (!startTime) return badRequest('Missing required field "startTime"');
    if (!endTime) return badRequest('Missing required field "endTime"');

    const { companies, errors: companyErrors } = parseCompaniesCsv(companiesCsv);
    if (companyErrors.length > 0) {
      return badRequest(`Companies CSV is invalid: ${companyErrors.join("; ")}`);
    }
    if (companies.length === 0) {
      return badRequest("Companies CSV contains no valid rows");
    }

    const { students, errors: studentErrors } = parseStudentsCsv(studentsCsv);
    if (studentErrors.length > 0) {
      return badRequest(`Students CSV is invalid: ${studentErrors.join("; ")}`);
    }
    if (students.length === 0) {
      return badRequest("Students CSV contains no valid rows");
    }

    const { window, error: windowError } = parseTimeWindow(startTime, endTime);
    if (windowError || !window) {
      return badRequest(windowError ?? "Invalid time window");
    }

    const { schedule, conflicts } = generateSchedule({
      students,
      companies,
      slot: window,
    });

    return Response.json({ schedule, conflicts }, { status: 200 });
  } catch (caught: unknown) {
    const message = caught instanceof Error ? caught.message : "Unknown server error";
    return badRequest(`Failed to process schedule request: ${message}`);
  }
}
