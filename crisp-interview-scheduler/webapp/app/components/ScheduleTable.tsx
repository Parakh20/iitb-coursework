import type { Interview } from "@/lib/types";

interface ScheduleTableProps {
  schedule: Interview[];
}

const BADGE_COLORS = [
  "bg-rose-100 text-rose-800 dark:bg-rose-900/40 dark:text-rose-300",
  "bg-amber-100 text-amber-800 dark:bg-amber-900/40 dark:text-amber-300",
  "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-300",
  "bg-sky-100 text-sky-800 dark:bg-sky-900/40 dark:text-sky-300",
  "bg-violet-100 text-violet-800 dark:bg-violet-900/40 dark:text-violet-300",
  "bg-pink-100 text-pink-800 dark:bg-pink-900/40 dark:text-pink-300",
];

function hashCompanyColor(companyName: string): string {
  let hash = 0;
  for (let i = 0; i < companyName.length; i++) {
    hash = (hash * 31 + companyName.charCodeAt(i)) % BADGE_COLORS.length;
  }
  return BADGE_COLORS[Math.abs(hash) % BADGE_COLORS.length];
}

function minutesToDisplayTime(totalMinutes: number): string {
  const hours24 = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  const period = hours24 >= 12 ? "PM" : "AM";
  const hours12 = hours24 % 12 === 0 ? 12 : hours24 % 12;
  return `${hours12}:${minutes.toString().padStart(2, "0")} ${period}`;
}

function groupByStudent(schedule: Interview[]): Map<string, Interview[]> {
  const grouped = new Map<string, Interview[]>();
  for (const interview of schedule) {
    const existing = grouped.get(interview.studentId) ?? [];
    grouped.set(interview.studentId, [...existing, interview]);
  }
  for (const [studentId, interviews] of grouped) {
    grouped.set(
      studentId,
      [...interviews].sort((a, b) => a.startTime - b.startTime)
    );
  }
  return grouped;
}

export function ScheduleTable({ schedule }: ScheduleTableProps) {
  if (schedule.length === 0) {
    return <p className="text-sm text-zinc-500 dark:text-zinc-400">No interviews scheduled yet.</p>;
  }

  const grouped = groupByStudent(schedule);

  return (
    <div className="flex flex-col gap-4">
      {Array.from(grouped.entries()).map(([studentId, interviews]) => (
        <div key={studentId} className="rounded-lg border border-zinc-200 bg-white p-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
          <h3 className="mb-2 font-semibold text-zinc-900 dark:text-zinc-50">{studentId}</h3>
          <ul className="flex flex-col gap-1">
            {interviews.map((interview, idx) => (
              <li key={`${interview.companyName}-${interview.round}-${idx}`} className="flex flex-wrap items-center gap-2 text-sm">
                <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${hashCompanyColor(interview.companyName)}`}>
                  {interview.companyName}
                </span>
                <span className="text-zinc-600 dark:text-zinc-400">Round {interview.round}</span>
                <span className="text-zinc-600 dark:text-zinc-400">
                  {minutesToDisplayTime(interview.startTime)} - {minutesToDisplayTime(interview.endTime)}
                </span>
                <span className="text-zinc-500 dark:text-zinc-500">Panel {interview.panelId}</span>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </div>
  );
}
