"""Exercise the real launchers without downloading a model or requiring a GPU."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cutout tests ")
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.env = dict(os.environ, PATH=str(self.work) + os.pathsep + os.environ["PATH"],
                        CUTOUT_CALL=str(self.work / "call.json"), CUTOUT_EXIT="0")
        fake = self.work / "fake_rembg.py"
        fake.write_text(
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "Path(os.environ['CUTOUT_CALL']).write_text(json.dumps(sys.argv[1:]))\n"
            "sys.exit(int(os.environ['CUTOUT_EXIT']))\n"
        )
        if os.name == "nt":
            (self.work / "rembg.bat").write_text(f'@echo off\npython "{fake}" %*\nexit /b %errorlevel%\n')
        else:
            command = self.work / "rembg"
            command.write_text(f'#!/usr/bin/env bash\nexec python3 "{fake}" "$@"\n')
            command.chmod(0o755)

    def run_tool(self, *args):
        if os.name == "nt":
            command = ["cmd.exe", "/c", str(ROOT / "cutout.bat"), *args]
        else:
            command = ["bash", str(ROOT / "cutout"), *args]
        return subprocess.run(command, cwd=self.work, env=self.env, text=True, capture_output=True)

    def test_usage(self):
        result = self.run_tool()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Usage: cutout", result.stdout + result.stderr)
        self.assertFalse((self.work / "call.json").exists())

    def test_missing_input(self):
        result = self.run_tool("missing.png")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("File not found", result.stdout + result.stderr)
        self.assertFalse((self.work / "call.json").exists())

    def test_model_and_output_path(self):
        for name in ("my portrait.png", "photo.v2.jpg", "no-extension"):
            with self.subTest(name=name):
                image = self.work / name
                image.touch()
                result = self.run_tool(str(image))
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                args = json.loads((self.work / "call.json").read_text())
                self.assertEqual(args, ["i", "-m", "birefnet-portrait", str(image),
                                       str(image.with_name(image.stem + "_nobg" + image.suffix))])
                self.assertIn("Background removal complete!", result.stdout)

    def test_failure_does_not_report_success(self):
        image = self.work / "portrait.png"
        image.touch()
        self.env["CUTOUT_EXIT"] = "7"
        result = self.run_tool(str(image))
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Background removal complete!", result.stdout)


@unittest.skipIf(os.name == "nt", "POSIX installer")
class InstallerTests(unittest.TestCase):
    def test_install_and_uninstall_preserve_other_commands(self):
        with tempfile.TemporaryDirectory(prefix="cutout bin ") as directory:
            target = Path(directory)
            other = target / "other-command"
            other.write_text("keep me")
            for _ in range(2):
                subprocess.run(["bash", str(ROOT / "install.sh"), directory], check=True, capture_output=True)
            self.assertEqual((target / "cutout").resolve(), ROOT / "cutout")
            for _ in range(2):
                subprocess.run(["bash", str(ROOT / "uninstall.sh"), directory], check=True, capture_output=True)
            self.assertFalse((target / "cutout").is_symlink())
            self.assertEqual(other.read_text(), "keep me")

    def test_install_refuses_to_replace_existing_file(self):
        with tempfile.TemporaryDirectory() as directory:
            command = Path(directory) / "cutout"
            command.write_text("another installation")
            result = subprocess.run(["bash", str(ROOT / "install.sh"), directory], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(command.read_text(), "another installation")

    def test_uninstall_preserves_foreign_symlink(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)
            other = target / "other"
            other.touch()
            (target / "cutout").symlink_to(other)
            subprocess.run(["bash", str(ROOT / "uninstall.sh"), directory], check=True, capture_output=True)
            self.assertEqual((target / "cutout").resolve(), other.resolve())


if __name__ == "__main__":
    unittest.main()
