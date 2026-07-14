#!/usr/bin/env python3
"""Simple GUI wrapper for the project table exporter."""

from __future__ import annotations

import threading
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

from table_exporter import export_tables


PROJECT_DIR = Path(__file__).resolve().parents[2]
DEFAULT_INPUT_DIR = PROJECT_DIR / "tables" / "excel"
DEFAULT_OUTPUT_DIR = PROJECT_DIR / "data" / "generated"


class TableExporterGui(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title("Project A Table Exporter")
        self.geometry("760x500")
        self.minsize(680, 440)

        self.input_dir = tk.StringVar(value=str(DEFAULT_INPUT_DIR))
        self.output_dir = tk.StringVar(value=str(DEFAULT_OUTPUT_DIR))
        self.clean_output = tk.BooleanVar(value=True)
        self.status = tk.StringVar(value="Ready")

        self._build_ui()

    def _build_ui(self) -> None:
        root = ttk.Frame(self, padding=16)
        root.pack(fill=tk.BOTH, expand=True)
        root.columnconfigure(1, weight=1)
        root.rowconfigure(5, weight=1)

        title = ttk.Label(root, text="Excel to JSON Exporter", font=("", 18, "bold"))
        title.grid(row=0, column=0, columnspan=3, sticky="w", pady=(0, 14))

        ttk.Label(root, text="Excel folder").grid(row=1, column=0, sticky="w", pady=6)
        ttk.Entry(root, textvariable=self.input_dir).grid(row=1, column=1, sticky="ew", padx=8)
        ttk.Button(root, text="Browse...", command=self._select_input_dir).grid(
            row=1, column=2, sticky="ew"
        )

        ttk.Label(root, text="JSON output").grid(row=2, column=0, sticky="w", pady=6)
        ttk.Entry(root, textvariable=self.output_dir).grid(row=2, column=1, sticky="ew", padx=8)
        ttk.Button(root, text="Browse...", command=self._select_output_dir).grid(
            row=2, column=2, sticky="ew"
        )

        ttk.Checkbutton(
            root,
            text="Clean old JSON files before exporting",
            variable=self.clean_output,
        ).grid(row=3, column=1, sticky="w", pady=(6, 12))

        self.export_button = ttk.Button(root, text="Export JSON", command=self._start_export)
        self.export_button.grid(row=4, column=0, sticky="w", pady=(0, 10))

        ttk.Label(root, textvariable=self.status).grid(row=4, column=1, columnspan=2, sticky="w")

        self.log = tk.Text(root, height=14, wrap="word", state="disabled")
        self.log.grid(row=5, column=0, columnspan=3, sticky="nsew")

        scrollbar = ttk.Scrollbar(root, orient="vertical", command=self.log.yview)
        scrollbar.grid(row=5, column=3, sticky="ns")
        self.log.configure(yscrollcommand=scrollbar.set)

        self._write_log("Select the Excel folder and JSON output folder, then export.")

    def _select_input_dir(self) -> None:
        selected = filedialog.askdirectory(
            title="Select Excel folder",
            initialdir=self.input_dir.get() or str(PROJECT_DIR),
        )
        if selected:
            self.input_dir.set(selected)

    def _select_output_dir(self) -> None:
        selected = filedialog.askdirectory(
            title="Select JSON output folder",
            initialdir=self.output_dir.get() or str(PROJECT_DIR),
        )
        if selected:
            self.output_dir.set(selected)

    def _start_export(self) -> None:
        input_dir = Path(self.input_dir.get()).expanduser()
        output_dir = Path(self.output_dir.get()).expanduser()

        if not input_dir.exists():
            messagebox.showerror("Missing Excel folder", f"Folder does not exist:\n{input_dir}")
            return

        self.export_button.configure(state="disabled")
        self.status.set("Exporting...")
        self._write_log("")
        self._write_log(f"Input: {input_dir}")
        self._write_log(f"Output: {output_dir}")

        thread = threading.Thread(
            target=self._run_export,
            args=(input_dir, output_dir, self.clean_output.get()),
            daemon=True,
        )
        thread.start()

    def _run_export(self, input_dir: Path, output_dir: Path, clean: bool) -> None:
        try:
            result = export_tables(input_dir, output_dir, clean)
        except Exception as exc:
            self.after(0, self._finish_with_exception, exc)
            return

        self.after(0, self._finish_export, result.exported_count, result.output_dir, result.errors)

    def _finish_export(self, exported_count: int, output_dir: Path, errors: list[object]) -> None:
        self.export_button.configure(state="normal")

        if errors:
            self.status.set("Export failed")
            self._write_log("Export failed:")
            for error in errors:
                self._write_log(f"  {error.format()}")
            messagebox.showerror("Export failed", "Some rows could not be exported. Check the log.")
            return

        self.status.set("Export complete")
        self._write_log(f"Exported {exported_count} table(s) to {output_dir}")
        messagebox.showinfo("Export complete", f"Exported {exported_count} table(s).")

    def _finish_with_exception(self, exc: Exception) -> None:
        self.export_button.configure(state="normal")
        self.status.set("Export failed")
        self._write_log(f"Error: {exc}")
        messagebox.showerror("Export failed", str(exc))

    def _write_log(self, message: str) -> None:
        self.log.configure(state="normal")
        self.log.insert(tk.END, message + "\n")
        self.log.see(tk.END)
        self.log.configure(state="disabled")


def main() -> None:
    app = TableExporterGui()
    app.mainloop()


if __name__ == "__main__":
    main()
