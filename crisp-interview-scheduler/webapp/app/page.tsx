"use client";

import { useState } from "react";
import { UploadForm } from "./components/UploadForm";
import { ScheduleTable } from "./components/ScheduleTable";
import { ConflictDashboard } from "./components/ConflictDashboard";
import { ExportButtons } from "./components/ExportButtons";
import type { Conflict, Interview } from "@/lib/types";

interface ScheduleApiResponse {
  schedule?: Interview[];
  conflicts?: Conflict[];
  error?: string;
}

export default function Home() {
  const [schedule, setSchedule] = useState<Interview[]>([]);
  const [conflicts, setConflicts] = useState<Conflict[]>([]);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (formData: FormData) => {
    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      const response = await fetch("/api/schedule", {
        method: "POST",
        body: formData,
      });

      const data: ScheduleApiResponse = await response.json();

      if (!response.ok || data.error) {
        setErrorMessage(data.error ?? "Failed to generate schedule");
        setSchedule([]);
        setConflicts([]);
        return;
      }

      setSchedule(data.schedule ?? []);
      setConflicts(data.conflicts ?? []);
    } catch (caught: unknown) {
      const message = caught instanceof Error ? caught.message : "Network error while scheduling";
      setErrorMessage(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen flex-col bg-zinc-50 font-sans dark:bg-black">
      <main className="mx-auto flex w-full max-w-4xl flex-col gap-8 px-6 py-12">
        <header>
          <h1 className="text-2xl font-bold text-zinc-900 dark:text-zinc-50">CRISP Interview Scheduler</h1>
          <p className="mt-1 text-sm text-zinc-600 dark:text-zinc-400">
            Upload company and student CSVs to generate a conflict-aware interview schedule.
          </p>
        </header>

        <UploadForm onSubmit={handleSubmit} isSubmitting={isSubmitting} />

        {errorMessage && (
          <div className="rounded-lg border border-red-300 bg-red-50 p-4 text-sm text-red-800 dark:border-red-900/60 dark:bg-red-950/30 dark:text-red-200">
            {errorMessage}
          </div>
        )}

        {(schedule.length > 0 || conflicts.length > 0) && (
          <>
            <section className="flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">Schedule</h2>
                <ExportButtons schedule={schedule} />
              </div>
              <ScheduleTable schedule={schedule} />
            </section>

            <section className="flex flex-col gap-3">
              <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">Conflicts</h2>
              <ConflictDashboard conflicts={conflicts} />
            </section>
          </>
        )}
      </main>
    </div>
  );
}
