import type { Interview } from "./types";

const MINUTES_PER_HOUR = 60;
const HOURS_PER_HALF_DAY = 12;

function minutesToDisplayTime(totalMinutes: number): string {
  const hours24 = Math.floor(totalMinutes / MINUTES_PER_HOUR);
  const minutes = totalMinutes % MINUTES_PER_HOUR;
  const period = hours24 >= HOURS_PER_HALF_DAY ? "PM" : "AM";
  const hours12 = hours24 % HOURS_PER_HALF_DAY === 0 ? HOURS_PER_HALF_DAY : hours24 % HOURS_PER_HALF_DAY;
  const minutesPadded = minutes.toString().padStart(2, "0");
  return `${hours12}:${minutesPadded} ${period}`;
}

function sortBySchedule(schedule: Interview[]): Interview[] {
  return [...schedule].sort((a, b) => {
    if (a.studentId !== b.studentId) {
      return a.studentId.localeCompare(b.studentId);
    }
    return a.startTime - b.startTime;
  });
}

function csvEscape(value: string): string {
  if (value.includes(",") || value.includes('"') || value.includes("\n")) {
    return `"${value.replace(/"/g, '""')}"`;
  }
  return value;
}

export function scheduleToCsv(schedule: Interview[]): string {
  const header = "studentId,companyName,round,startTime,endTime,panelId";
  const rows = sortBySchedule(schedule).map((interview) => {
    return [
      csvEscape(interview.studentId),
      csvEscape(interview.companyName),
      interview.round.toString(),
      minutesToDisplayTime(interview.startTime),
      minutesToDisplayTime(interview.endTime),
      interview.panelId.toString(),
    ].join(",");
  });

  return [header, ...rows].join("\n");
}

export async function scheduleToPdf(schedule: Interview[]): Promise<Uint8Array> {
  const { default: JsPDF } = await import("jspdf");
  const { default: autoTable } = await import("jspdf-autotable");

  const doc = new JsPDF();
  const sorted = sortBySchedule(schedule);

  const body = sorted.map((interview) => [
    interview.studentId,
    interview.companyName,
    interview.round.toString(),
    minutesToDisplayTime(interview.startTime),
    minutesToDisplayTime(interview.endTime),
    interview.panelId.toString(),
  ]);

  autoTable(doc, {
    head: [["Student", "Company", "Round", "Start", "End", "Panel"]],
    body,
  });

  const arrayBuffer = doc.output("arraybuffer") as ArrayBuffer;
  return new Uint8Array(arrayBuffer);
}
