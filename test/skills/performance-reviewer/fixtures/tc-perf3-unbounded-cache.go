package geo

import (
	"encoding/json"
	"net/http"
	"sync"
)

type Location struct {
	Lat     float64 `json:"lat"`
	Lng     float64 `json:"lng"`
	Country string  `json:"country"`
}

type Geocoder interface {
	Lookup(address string) (Location, error)
}

type Handler struct {
	geocoder Geocoder
	mu       sync.RWMutex
	results  map[string]Location
}

func NewHandler(g Geocoder) *Handler {
	return &Handler{geocoder: g, results: make(map[string]Location)}
}

// ServeHTTP handles GET /geocode?address=... for the public storefront's
// address autocomplete, called on each debounced keystroke.
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	address := r.URL.Query().Get("address")
	if address == "" {
		http.Error(w, "address required", http.StatusBadRequest)
		return
	}

	h.mu.RLock()
	loc, ok := h.results[address]
	h.mu.RUnlock()

	if !ok {
		var err error
		loc, err = h.geocoder.Lookup(address)
		if err != nil {
			http.Error(w, "lookup failed", http.StatusBadGateway)
			return
		}
		h.mu.Lock()
		h.results[address] = loc
		h.mu.Unlock()
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(loc)
}
