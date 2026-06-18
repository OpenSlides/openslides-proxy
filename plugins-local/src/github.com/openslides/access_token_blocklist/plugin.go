package access_token_blocklist

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

// Mandatory config struct
type Config struct {
}

func CreateConfig() *Config {
	return &Config{}
}

type AccessTokenBlocklist struct {
	next              http.Handler
	name              string
	blockedSessionIDs map[string]int
	id                int
}

// Create new plugin instance
func New(ctx context.Context, next http.Handler, config *Config, name string) (http.Handler, error) {
	return &AccessTokenBlocklist{
		next:              next,
		name:              name,
		blockedSessionIDs: make(map[string]int),
	}, nil
}

type responseWriter struct {
	http.ResponseWriter
	flusher   http.Flusher
	userID    string
	headerSet bool
}

func (w *responseWriter) WriteHeader(code int) {
	w.Header().Set(userIDHeader, w.userID)
	w.headerSet = true
	w.ResponseWriter.WriteHeader(code)
}

func (w *responseWriter) Write(b []byte) (int, error) {
	if !w.headerSet {
		w.Header().Set(userIDHeader, w.userID)
	}

	n, err := w.ResponseWriter.Write(b)
	if w.flusher != nil {
		w.flusher.Flush()
	}

	return n, err
}

func (w *responseWriter) Flush() {
	if w.flusher != nil {
		w.flusher.Flush()
	}
}

func extractSessionID(r *http.Request) string {
	header := r.Header.Get("Authorization")
	encodedToken := strings.TrimPrefix(header, "Bearer: ")

	if header == encodedToken {
		// No token. Handle the request as public access requst.
		fmt.Println("header error: no token")
		return ""
	}

	parts := strings.Split(encodedToken, ".")
	if len(parts) != 3 {
		fmt.Println("header error: JWT partition not length 3")
		return ""
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		fmt.Println("header error: decoding token payload:", err)
		return ""
	}

	var claims map[string]any
	if err := json.Unmarshal(payload, &claims); err != nil {
		fmt.Println("header error: parsing token claims:", err)
		return ""
	}

	sid, exists := claims["sid"]
	if !exists {
		fmt.Println("header error: missing sid in token claims")
		return ""
	}

	return sid.(string)
}

func (a *AccessTokenBlocklist) blockSessionID(sessionID string) {
	a.blockedSessionIDs[sessionID] = 1
}

func (a *AccessTokenBlocklist) isSessionIDBlocked(sessionID string) bool {
	if _, exists := a.blockedSessionIDs[sessionID]; exists {
		return true
	}
	return false
}

func (a *AccessTokenBlocklist) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	sessionID := extractSessionID(r)

	if strings.HasSuffix(r.URL.Path, logoutRoute) {
		a.blockSessionID(sessionID)
	}

	var flusher http.Flusher
	if f, ok := w.(http.Flusher); ok {
		flusher = f
	}
	if a.isSessionIDBlocked(sessionID) {
		// Write it as a new header
		r.Header.Set(userIDHeader, "0")

		// Pass
		a.next.ServeHTTP(&responseWriter{
			flusher:        flusher,
			ResponseWriter: w,
			userID:         "0",
		}, r)
		return
	}

	// Pass
	a.next.ServeHTTP(&responseWriter{
		flusher:        flusher,
		ResponseWriter: w,
	}, r)

}

const (
	userIDHeader string = "X-User-ID"
	logoutRoute  string = "system/logout"
)
