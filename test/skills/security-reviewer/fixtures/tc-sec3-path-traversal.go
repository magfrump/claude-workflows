package exports

import (
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

type Server struct {
	ExportDir string
}

func (s *Server) HandleDownload(w http.ResponseWriter, r *http.Request) {
	user, ok := r.Context().Value(userKey).(*User)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	name := r.URL.Query().Get("file")
	if name == "" || !strings.HasSuffix(name, ".csv") {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	full := filepath.Join(s.ExportDir, user.ID, name)
	f, err := os.Open(full)
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}
	defer f.Close()

	w.Header().Set("Content-Type", "text/csv")
	w.Header().Set("Content-Disposition", "attachment; filename=\""+filepath.Base(full)+"\"")
	_, _ = io.Copy(w, f)
}
