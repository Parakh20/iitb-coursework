import type { Conflict } from "@/lib/types";

interface ConflictDashboardProps {
  conflicts: Conflict[];
}

export function ConflictDashboard({ conflicts }: ConflictDashboardProps) {
  if (conflicts.length === 0) {
    return (
      <p className="text-sm text-emerald-700 dark:text-emerald-400">
        No conflicts — every shortlisted interview was scheduled.
      </p>
    );
  }

  return (
    <div className="overflow-x-auto rounded-lg border border-amber-200 bg-amber-50 dark:border-amber-900/60 dark:bg-amber-950/30">
      <table className="w-full text-left text-sm">
        <thead>
          <tr className="border-b border-amber-200 dark:border-amber-900/60">
            <th className="px-3 py-2 font-semibold text-amber-900 dark:text-amber-200">Student</th>
            <th className="px-3 py-2 font-semibold text-amber-900 dark:text-amber-200">Company</th>
            <th className="px-3 py-2 font-semibold text-amber-900 dark:text-amber-200">Round</th>
            <th className="px-3 py-2 font-semibold text-amber-900 dark:text-amber-200">Reason</th>
          </tr>
        </thead>
        <tbody>
          {conflicts.map((conflict, idx) => (
            <tr key={`${conflict.studentId}-${conflict.companyName}-${idx}`} className="border-b border-amber-100 last:border-0 dark:border-amber-900/40">
              <td className="px-3 py-2 text-amber-900 dark:text-amber-100">{conflict.studentId}</td>
              <td className="px-3 py-2 text-amber-900 dark:text-amber-100">{conflict.companyName}</td>
              <td className="px-3 py-2 text-amber-900 dark:text-amber-100">{conflict.round ?? "-"}</td>
              <td className="px-3 py-2 text-amber-800 dark:text-amber-200">{conflict.reason}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
