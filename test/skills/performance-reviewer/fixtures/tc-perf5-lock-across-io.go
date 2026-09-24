package quotes

import (
	"encoding/json"
	"net/http"
	"sync"
	"time"
)

type Quote struct {
	Symbol string  `json:"symbol"`
	Price  float64 `json:"price"`
}

type Service struct {
	client   *http.Client
	upstream string

	mu       sync.Mutex
	requests map[string]int
	lastSeen map[string]time.Time
}

func NewService(upstream string) *Service {
	return &Service{
		client:   &http.Client{Timeout: 5 * time.Second},
		upstream: upstream,
		requests: make(map[string]int),
		lastSeen: make(map[string]time.Time),
	}
}

// HandleQuote serves GET /quote?symbol=XYZ for the trading dashboard.
func (s *Service) HandleQuote(w http.ResponseWriter, r *http.Request) {
	symbol := r.URL.Query().Get("symbol")

	s.mu.Lock()
	defer s.mu.Unlock()

	resp, err := s.client.Get(s.upstream + "/v1/quote/" + symbol)
	if err != nil {
		http.Error(w, "upstream error", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	var q Quote
	if err := json.NewDecoder(resp.Body).Decode(&q); err != nil {
		http.Error(w, "bad upstream payload", http.StatusBadGateway)
		return
	}

	s.requests[symbol]++
	s.lastSeen[symbol] = time.Now()

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(q)
}
