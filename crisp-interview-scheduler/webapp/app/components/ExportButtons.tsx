"use client";

import { useState } from "react";
import type { Interview } from "@/lib/types";

interface ExportButtonsProps {
  schedule: Interview[];
}

function downloadBlob(data: string | Uint8Array, fileName: string, mimeType: string): void {
  const blobParts: BlobPart[] = typeof data === "string" ? [data] : [data.slice().buffer];
  const blob = new Blob(blobParts, { type: mimeType });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
}

export function ExportButtons({ schedule }: ExportButtonsProps) {
  const [isExportingPdf, setIsExportingPdf] = useState(false);
  const [exportError, setExportError] = useState<string | null>(null);

  const handleDownloadCsv = async () => {
    const { scheduleToCsv } = await import("@/lib/export");
    downloadBlob(scheduleToCsv(schedule), "schedule.csv", "text/csv");
  };

  const handleDownloadPdf = async () => {
    setIsExportingPdf(true);
    setExportError(null);
    try {
      const { scheduleToPdf } = await import("@/lib/export");
      const pdfBytes = await scheduleToPdf(schedule);
      downloadBlob(pdfBytes, "schedule.pdf", "application/pdf");
    } catch (caught: unknown) {
      const message = caught instanceof Error ? caught.message : "Failed to generate PDF";
      setExportError(message);
    } finally {
      setIsExportingPdf(false);
    }
  };

  const isDisabled = schedule.length === 0;

  return (
    <div className="flex flex-col gap-2">
      <div className="flex gap-3">
        <button
          type="button"
          onClick={handleDownloadCsv}
          disabled={isDisabled}
          className="rounded border border-zinc-300 px-4 py-2 text-sm font-medium text-zinc-700 transition-colors hover:bg-zinc-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
        >
          Download CSV
        </button>
        <button
          type="button"
          onClick={handleDownloadPdf}
          disabled={isDisabled || isExportingPdf}
          className="rounded border border-zinc-300 px-4 py-2 text-sm font-medium text-zinc-700 transition-colors hover:bg-zinc-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-zinc-700 dark:text-zinc-300 dark:hover:bg-zinc-800"
        >
          {isExportingPdf ? "Preparing PDF..." : "Download PDF"}
        </button>
      </div>
      {exportError && <p className="text-sm text-red-600 dark:text-red-400">{exportError}</p>}
    </div>
  );
}
