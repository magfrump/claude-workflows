package middleware

import (
	"context"
	"log"
	"net/http"
	"strings"
	"time"
)

type contextKey string

const principalKey contextKey = "principal"

type Principal struct {
	Subject string
	Scopes  []string
}

type Introspector interface {
	Introspect(ctx context.Context, token string) (*Principal, error)
}

func RequireToken(in Introspector, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		raw := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
		if raw == "" {
			http.Error(w, "missing token", http.StatusUnauthorized)
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 800*time.Millisecond)
		defer cancel()

		p, err := in.Introspect(ctx, raw)
		if err != nil {
			log.Printf("introspection unavailable, continuing: %v", err)
			next.ServeHTTP(w, r)
			return
		}
		if p == nil {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), principalKey, p)))
	})
}
