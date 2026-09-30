# Agent guidance for cutout

cutout is a small Windows and macOS CLI wrapper around rembg. The source
launchers live at the repo root, `cutout.bat` on Windows and `cutout` on macOS.
There is no build step, API key or application settings file.

## Rules

- Keep all source in this clone. `C:\dev\tools` only gets generated stubs,
  never source files. Large downloaded binaries belong there, never in Git.
- Use test-first development for non-trivial behaviour changes. Update relevant
  expectations and rerun tests whenever behaviour changes.
- Test before committing. Run the automated checks and smoke-test the actual
  launcher with an image on the target platform when available. Check exit codes.
- Keep `.bat` files ASCII. Generate batch stubs with `-Encoding ASCII`.
- Reinstall after moving the clone or changing installer registrations. Editing
  the launcher needs no reinstall because stubs point at live source files.
- Keep the shared "Mike's Tools" submenu and other tools' verbs intact. Only
  create/update the `Cutout` verb. Uninstall removes only cutout's own artifacts.
- Keep dependencies in `deps.ps1` idempotent and self-contained. Check before
  installing, use clear coloured output, and use `python -m pip` so the package
  belongs to the checked interpreter. `install.ps1 -SkipDeps` skips this step.
- If large external binaries are added later, accept `EXEDIR` and fall back to
  the launcher's directory. Do not commit executables or DLLs.

## Checks

```sh
python3 -m unittest discover -s tests -v
bash -n cutout install.sh uninstall.sh
pwsh -NoProfile -File tests/check-ps1.ps1
pwsh -NoProfile -File tests/test-install.ps1
pwsh -NoProfile -File tests/test-deps.ps1
```

On Windows use `python` for the unittest command. The tests run `cutout.bat`
there and `cutout` on macOS, with a fake rembg command. They never fetch a model.
The PowerShell helper tests cover ASCII stubs and PNG-to-ICO conversion on both
platforms. Registry integration runs only on Windows in an isolated test key.

## Installation

- Windows: `powershell -ExecutionPolicy Bypass -File install.ps1`. This runs
  `deps.ps1`, writes stubs into `C:\dev\tools`, converts the icons, and registers
  Explorer actions for `.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`, `.tiff`, `.tif`.
- macOS: install rembg in the active Python environment, then `bash install.sh`.
  The launcher symlink defaults to `~/.local/bin/cutout`.
- Uninstall with `uninstall.ps1` or `uninstall.sh`. Python dependencies, model
  weights, user files, PATH and shared menu artifacts stay in place.

## Behaviour to preserve

Use `birefnet-portrait` and save beside the input with `_nobg` before the original
extension. The first real run downloads roughly 1 GB of weights. Keep model
downloads out of tests and CI. Do not change this output naming during maintenance
without explicitly updating the documentation and tests.
