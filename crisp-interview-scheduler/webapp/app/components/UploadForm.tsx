"use client";

import { useState, type FormEvent } from "react";

interface UploadFormProps {
  onSubmit: (formData: FormData) => Promise<void>;
  isSubmitting: boolean;
}

interface CompanyRow {
  name: string;
  durationPerRound: string;
  numRounds: string;
  numPanels: string;
}

interface StudentRow {
  rollNumber: string;
  name: string;
  shortlistedCompanies: string;
}

const DEFAULT_COMPANY: CompanyRow = { name: "", durationPerRound: "30", numRounds: "1", numPanels: "1" };
const DEFAULT_STUDENT: StudentRow = { rollNumber: "", name: "", shortlistedCompanies: "" };

function rowsToCsv<T extends object>(headers: (keyof T & string)[], rows: T[]): string {
  const lines = rows.map((row) => headers.map((h) => (row[h] as string | undefined) ?? "").join(","));
  return [headers.join(","), ...lines].join("\n");
}

export function UploadForm({ onSubmit, isSubmitting }: UploadFormProps) {
  const [mode, setMode] = useState<"upload" | "manual">("upload");
  const [startTime, setStartTime] = useState("09:00");
  const [endTime, setEndTime] = useState("18:00");

  // Manual mode state
  const [companies, setCompanies] = useState<CompanyRow[]>([{ ...DEFAULT_COMPANY }]);
  const [students, setStudents] = useState<StudentRow[]>([{ ...DEFAULT_STUDENT }]);

  const handleUploadSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const formData = new FormData(event.currentTarget);
    await onSubmit(formData);
  };

  const handleManualSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const companiesCsv = rowsToCsv<CompanyRow>(["name", "durationPerRound", "numRounds", "numPanels"], companies);
    const studentsCsv = rowsToCsv<StudentRow>(["rollNumber", "name", "shortlistedCompanies"], students);

    const formData = new FormData();
    formData.append("companies", new File([companiesCsv], "companies.csv", { type: "text/csv" }));
    formData.append("students", new File([studentsCsv], "students.csv", { type: "text/csv" }));
    formData.append("startTime", startTime);
    formData.append("endTime", endTime);
    await onSubmit(formData);
  };

  const updateCompany = (index: number, field: keyof CompanyRow, value: string) => {
    setCompanies((prev) => prev.map((row, i) => (i === index ? { ...row, [field]: value } : row)));
  };

  const updateStudent = (index: number, field: keyof StudentRow, value: string) => {
    setStudents((prev) => prev.map((row, i) => (i === index ? { ...row, [field]: value } : row)));
  };

  const removeCompany = (index: number) => {
    setCompanies((prev) => prev.filter((_, i) => i !== index));
  };

  const removeStudent = (index: number) => {
    setStudents((prev) => prev.filter((_, i) => i !== index));
  };

  const inputCls = "w-full rounded border border-zinc-300 bg-zinc-50 px-2 py-1.5 text-sm dark:border-zinc-700 dark:bg-zinc-800";
  const timeCls = "rounded border border-zinc-300 bg-zinc-50 p-2 text-sm dark:border-zinc-700 dark:bg-zinc-800";

  const timeFields = (
    <div className="flex gap-4">
      <label className="flex flex-1 flex-col gap-1 text-sm font-medium text-zinc-700 dark:text-zinc-300">
        Start Time
        <input type="time" value={startTime} onChange={(e) => setStartTime(e.target.value)} required className={timeCls} />
      </label>
      <label className="flex flex-1 flex-col gap-1 text-sm font-medium text-zinc-700 dark:text-zinc-300">
        End Time
        <input type="time" value={endTime} onChange={(e) => setEndTime(e.target.value)} required className={timeCls} />
      </label>
    </div>
  );

  const submitButton = (
    <button
      type="submit"
      disabled={isSubmitting}
      className="mt-2 rounded bg-zinc-900 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-zinc-700 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-zinc-50 dark:text-zinc-900 dark:hover:bg-zinc-300"
    >
      {isSubmitting ? "Generating Schedule..." : "Generate Schedule"}
    </button>
  );

  return (
    <div className="flex flex-col gap-4 rounded-lg border border-zinc-200 bg-white p-6 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-zinc-900 dark:text-zinc-50">Schedule Inputs</h2>
        {mode === "upload" && (
          <div className="flex gap-3 text-xs text-zinc-500 dark:text-zinc-400">
            <span>Sample files:</span>
            <a href="/samples/companies.csv" download className="underline underline-offset-2 hover:text-zinc-800 dark:hover:text-zinc-200">companies.csv</a>
            <a href="/samples/students.csv" download className="underline underline-offset-2 hover:text-zinc-800 dark:hover:text-zinc-200">students.csv</a>
          </div>
        )}
      </div>

      {/* Mode tabs */}
      <div className="flex gap-1 rounded-md border border-zinc-200 bg-zinc-100 p-1 dark:border-zinc-700 dark:bg-zinc-800">
        {(["upload", "manual"] as const).map((m) => (
          <button
            key={m}
            type="button"
            onClick={() => setMode(m)}
            className={`flex-1 rounded px-3 py-1.5 text-sm font-medium transition-colors ${
              mode === m
                ? "bg-white text-zinc-900 shadow-sm dark:bg-zinc-900 dark:text-zinc-50"
                : "text-zinc-500 hover:text-zinc-700 dark:text-zinc-400 dark:hover:text-zinc-200"
            }`}
          >
            {m === "upload" ? "Upload CSV" : "Enter Manually"}
          </button>
        ))}
      </div>

      {/* Upload mode */}
      {mode === "upload" && (
        <form onSubmit={handleUploadSubmit} className="flex flex-col gap-4">
          <label className="flex flex-col gap-1 text-sm font-medium text-zinc-700 dark:text-zinc-300">
            Companies CSV
            <input type="file" name="companies" accept=".csv" required className="rounded border border-zinc-300 bg-zinc-50 p-2 text-sm dark:border-zinc-700 dark:bg-zinc-800" />
          </label>
          <label className="flex flex-col gap-1 text-sm font-medium text-zinc-700 dark:text-zinc-300">
            Students CSV
            <input type="file" name="students" accept=".csv" required className="rounded border border-zinc-300 bg-zinc-50 p-2 text-sm dark:border-zinc-700 dark:bg-zinc-800" />
          </label>
          {/* hidden time fields so the form can read them */}
          <input type="hidden" name="startTime" value={startTime} />
          <input type="hidden" name="endTime" value={endTime} />
          {timeFields}
          {submitButton}
        </form>
      )}

      {/* Manual mode */}
      {mode === "manual" && (
        <form onSubmit={handleManualSubmit} className="flex flex-col gap-6">
          {/* Companies table */}
          <section className="flex flex-col gap-2">
            <h3 className="text-sm font-semibold text-zinc-800 dark:text-zinc-200">Companies</h3>
            <div className="overflow-x-auto rounded border border-zinc-200 dark:border-zinc-700">
              <table className="w-full text-sm">
                <thead className="bg-zinc-50 dark:bg-zinc-800">
                  <tr>
                    {["Name", "Duration (min)", "Rounds", "Panels", ""].map((h) => (
                      <th key={h} className="px-3 py-2 text-left text-xs font-semibold text-zinc-600 dark:text-zinc-400">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800">
                  {companies.map((row, i) => (
                    <tr key={i}>
                      <td className="px-2 py-1.5">
                        <input value={row.name} onChange={(e) => updateCompany(i, "name", e.target.value)} placeholder="e.g. CompanyA" required className={inputCls} />
                      </td>
                      <td className="px-2 py-1.5">
                        <input type="number" min="1" value={row.durationPerRound} onChange={(e) => updateCompany(i, "durationPerRound", e.target.value)} required className={inputCls} />
                      </td>
                      <td className="px-2 py-1.5">
                        <input type="number" min="1" value={row.numRounds} onChange={(e) => updateCompany(i, "numRounds", e.target.value)} required className={inputCls} />
                      </td>
                      <td className="px-2 py-1.5">
                        <input type="number" min="1" value={row.numPanels} onChange={(e) => updateCompany(i, "numPanels", e.target.value)} required className={inputCls} />
                      </td>
                      <td className="px-2 py-1.5">
                        <button
                          type="button"
                          onClick={() => removeCompany(i)}
                          disabled={companies.length === 1}
                          className="rounded px-2 py-1 text-xs text-red-500 hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-30 dark:hover:bg-red-950"
                        >
                          Remove
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <button
              type="button"
              onClick={() => setCompanies((prev) => [...prev, { ...DEFAULT_COMPANY }])}
              className="self-start rounded border border-dashed border-zinc-300 px-3 py-1.5 text-xs text-zinc-500 hover:border-zinc-400 hover:text-zinc-700 dark:border-zinc-600 dark:hover:border-zinc-400 dark:hover:text-zinc-300"
            >
              + Add Company
            </button>
          </section>

          {/* Students table */}
          <section className="flex flex-col gap-2">
            <h3 className="text-sm font-semibold text-zinc-800 dark:text-zinc-200">Students</h3>
            <div className="overflow-x-auto rounded border border-zinc-200 dark:border-zinc-700">
              <table className="w-full text-sm">
                <thead className="bg-zinc-50 dark:bg-zinc-800">
                  <tr>
                    {["Roll No.", "Name (optional)", "Shortlisted Companies (semicolon-separated)", ""].map((h) => (
                      <th key={h} className="px-3 py-2 text-left text-xs font-semibold text-zinc-600 dark:text-zinc-400">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-100 dark:divide-zinc-800">
                  {students.map((row, i) => (
                    <tr key={i}>
                      <td className="px-2 py-1.5">
                        <input value={row.rollNumber} onChange={(e) => updateStudent(i, "rollNumber", e.target.value)} placeholder="e.g. 101" required className={inputCls} />
                      </td>
                      <td className="px-2 py-1.5">
                        <input value={row.name} onChange={(e) => updateStudent(i, "name", e.target.value)} placeholder="e.g. Alice" className={inputCls} />
                      </td>
                      <td className="px-2 py-1.5">
                        <input value={row.shortlistedCompanies} onChange={(e) => updateStudent(i, "shortlistedCompanies", e.target.value)} placeholder="e.g. CompanyA;CompanyB" className={inputCls} />
                      </td>
                      <td className="px-2 py-1.5">
                        <button
                          type="button"
                          onClick={() => removeStudent(i)}
                          disabled={students.length === 1}
                          className="rounded px-2 py-1 text-xs text-red-500 hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-30 dark:hover:bg-red-950"
                        >
                          Remove
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <button
              type="button"
              onClick={() => setStudents((prev) => [...prev, { ...DEFAULT_STUDENT }])}
              className="self-start rounded border border-dashed border-zinc-300 px-3 py-1.5 text-xs text-zinc-500 hover:border-zinc-400 hover:text-zinc-700 dark:border-zinc-600 dark:hover:border-zinc-400 dark:hover:text-zinc-300"
            >
              + Add Student
            </button>
          </section>

          {timeFields}
          {submitButton}
        </form>
      )}
    </div>
  );
}
