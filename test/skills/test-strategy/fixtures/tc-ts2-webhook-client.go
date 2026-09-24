package notify

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"strconv"
	"testing"
	"time"
)

// Client posts delivery events to a partner's webhook endpoint.
type Client struct {
	HTTP        *http.Client
	Endpoint    string
	MaxAttempts int
	Sleep       func(time.Duration)
}

type StatusError struct {
	Code int
}

func (e *StatusError) Error() string { return fmt.Sprintf("webhook returned %d", e.Code) }

func retryable(code int) bool {
	return code == http.StatusTooManyRequests || code >= 500
}

func backoff(attempt int, resp *http.Response) time.Duration {
	if resp != nil {
		if s := resp.Header.Get("Retry-After"); s != "" {
			if secs, err := strconv.Atoi(s); err == nil && secs >= 0 {
				return time.Duration(secs) * time.Second
			}
		}
	}
	return time.Duration(1<<attempt) * 250 * time.Millisecond
}

func (c *Client) Send(ctx context.Context, body []byte) error {
	var lastErr error
	for attempt := 0; attempt < c.MaxAttempts; attempt++ {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.Endpoint, bytes.NewReader(body))
		if err != nil {
			return err
		}
		req.Header.Set("Content-Type", "application/json")

		resp, err := c.HTTP.Do(req)
		if err != nil {
			return err
		}
		resp.Body.Close()

		if resp.StatusCode < 300 {
			return nil
		}
		lastErr = &StatusError{Code: resp.StatusCode}
		if !retryable(resp.StatusCode) {
			return lastErr
		}
		c.Sleep(backoff(attempt, resp))
	}
	return lastErr
}

// --- tests (client_test.go) ---

type fakeTransport struct {
	codes []int
	calls int
}

func (f *fakeTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	code := f.codes[f.calls]
	f.calls++
	return &http.Response{StatusCode: code, Body: http.NoBody, Header: http.Header{}}, nil
}

func newTestClient(ft *fakeTransport) *Client {
	return &Client{
		HTTP:        &http.Client{Transport: ft},
		Endpoint:    "https://partner.example.test/hooks",
		MaxAttempts: 4,
		Sleep:       func(time.Duration) {},
	}
}

func TestSendSucceedsFirstTry(t *testing.T) {
	ft := &fakeTransport{codes: []int{204}}
	if err := newTestClient(ft).Send(context.Background(), []byte(`{}`)); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if ft.calls != 1 {
		t.Fatalf("calls = %d, want 1", ft.calls)
	}
}

func TestSendDoesNotRetryClientErrors(t *testing.T) {
	for _, code := range []int{400, 404, 410} {
		ft := &fakeTransport{codes: []int{code}}
		err := newTestClient(ft).Send(context.Background(), []byte(`{}`))
		se, ok := err.(*StatusError)
		if !ok || se.Code != code {
			t.Fatalf("code %d: err = %v", code, err)
		}
		if ft.calls != 1 {
			t.Fatalf("code %d: calls = %d, want 1", code, ft.calls)
		}
	}
}
