package repoview

import (
	"context"
	"net/http"
	"os/exec"
	"regexp"
	"time"
)

var commitSHA = regexp.MustCompile(`^[0-9a-f]{40}$`)

type Handler struct {
	RepoDir string
}

func (h *Handler) CommitStat(w http.ResponseWriter, r *http.Request) {
	if _, ok := SessionFrom(r.Context()); !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	sha := r.URL.Query().Get("sha")
	if !commitSHA.MatchString(sha) {
		http.Error(w, "sha must be a full 40-character hex commit id", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "git", "-C", h.RepoDir, "show", "--stat", "--format=%H%n%an%n%s", sha)
	out, err := cmd.Output()
	if err != nil {
		http.Error(w, "commit not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = w.Write(out)
}
