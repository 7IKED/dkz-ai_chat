// ╔══════════════════════════════════════════════════════════════════╗
// ║  ODYSSEUS // SINGLE-FILE LAUNCHER  ·  DEVKiTZ Version 3            ║
// ║  Eine Datei (odysseus.exe / odysseus-linux) mit eingebettetem      ║
// ║  Komplett-System: entpackt sich nach C:\DEVKiTZ\odysseus bzw.     ║
// ║  ~/DEVKiTZ/odysseus und startet die Umgebung.                     ║
// ║  Nur Go-Stdlib · MIT · keine Abhaengigkeiten.                     ║
// ╚══════════════════════════════════════════════════════════════════╝
package main

import (
	"archive/tar"
	"compress/gzip"
	"bytes"
	_ "embed"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

//go:embed payload.tar.gz
var payload []byte

const (
	green = "\033[38;5;46m"
	dim   = "\033[38;5;28m"
	reset = "\033[0m"
)

func target() string {
	if t := os.Getenv("ODYSSEUS_TARGET"); t != "" {
		return t
	}
	if runtime.GOOS == "windows" {
		return `C:\DEVKiTZ\odysseus`
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, "DEVKiTZ", "odysseus")
}

func extract(dst string) error {
	gz, err := gzip.NewReader(bytes.NewReader(payload))
	if err != nil {
		return err
	}
	tr := tar.NewReader(gz)
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}
		// Pfad absichern (kein ZipSlip)
		name := filepath.Clean(hdr.Name)
		if strings.HasPrefix(name, "..") || filepath.IsAbs(name) {
			continue
		}
		p := filepath.Join(dst, name)
		switch hdr.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(p, 0o755); err != nil {
				return err
			}
		case tar.TypeReg:
			// .env nie ueberschreiben (Update-faehig)
			if filepath.Base(p) == ".env" {
				if _, err := os.Stat(p); err == nil {
					continue
				}
			}
			if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
				return err
			}
			f, err := os.OpenFile(p, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, os.FileMode(hdr.Mode)|0o644)
			if err != nil {
				return err
			}
			if _, err := io.Copy(f, tr); err != nil {
				f.Close()
				return err
			}
			f.Close()
		}
	}
	return nil
}

func main() {
	fmt.Println(green + `
 ██████╗ ██████╗ ██╗   ██╗███████╗███████╗███████╗██╗   ██╗███████╗
██╔═══██╗██╔══██╗╚██╗ ██╔╝██╔════╝██╔════╝██╔════╝██║   ██║██╔════╝
██║   ██║██║  ██║ ╚████╔╝ ███████╗███████╗█████╗  ██║   ██║███████╗
██║   ██║██║  ██║  ╚██╔╝  ╚════██║╚════██║██╔══╝  ██║   ██║╚════██║
╚██████╔╝██████╔╝   ██║   ███████║███████║███████╗╚██████╔╝███████║
 ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚══════╝
        DEVKiTZ Version 3 · Single-File · Matrix` + reset)

	dst := target()
	fmt.Printf("%s[ODYSSEUS]%s entpacke System nach %s ...\n", green, reset, dst)
	if err := os.MkdirAll(dst, 0o755); err != nil {
		fmt.Println("FEHLER:", err)
		os.Exit(1)
	}
	if err := extract(dst); err != nil {
		fmt.Println("FEHLER beim Entpacken:", err)
		os.Exit(1)
	}
	// .env aus Vorlage, falls neu
	env := filepath.Join(dst, ".env")
	if _, err := os.Stat(env); os.IsNotExist(err) {
		if b, err := os.ReadFile(filepath.Join(dst, ".env.example")); err == nil {
			os.WriteFile(env, b, 0o600)
			fmt.Printf("%s[ODYSSEUS]%s .env angelegt — Passwoerter aendern: %s\n", green, reset, env)
		}
	}
	fmt.Printf("%s[ODYSSEUS]%s System bereit.\n\n", green, reset)

	// Naechste Schritte / Autostart
	dockerOK := exec.Command("docker", "version").Run() == nil
	if runtime.GOOS == "windows" {
		fmt.Println(dim + "  Naechste Schritte:" + reset)
		if !dockerOK {
			fmt.Println("  1) Docker Desktop installieren: https://docker.com")
		} else {
			fmt.Println("  1) Stack starten:   cd " + dst + " && docker compose up -d")
		}
		fmt.Println("  2) Terminal (WSL):  wsl -- bash -lic \"" + wslPath(dst) + "/bin/odysseus\"")
		fmt.Println("  3) Gitea einrichten: odysseus init")
		fmt.Println("\n  [Enter] zum Beenden")
		fmt.Scanln()
		return
	}
	// Linux/macOS: Rechte setzen und direkt anbieten
	exec.Command("chmod", "-R", "+x", filepath.Join(dst, "bin"), filepath.Join(dst, "scripts")).Run()
	if dockerOK {
		fmt.Printf("%s[ODYSSEUS]%s starte Stack (docker compose up -d) ...\n", green, reset)
		cmd := exec.Command("docker", "compose", "up", "-d")
		cmd.Dir = dst
		cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
		cmd.Run()
	} else {
		fmt.Println(dim + "  Docker fehlt — Stack spaeter: cd " + dst + " && docker compose up -d" + reset)
	}
	fmt.Println(dim + "  Terminal:  " + filepath.Join(dst, "bin", "odysseus") + reset)
}

func wslPath(p string) string {
	p = strings.ReplaceAll(p, `\`, `/`)
	if len(p) > 2 && p[1] == ':' {
		p = "/mnt/" + strings.ToLower(p[:1]) + p[2:]
	}
	return p
}
