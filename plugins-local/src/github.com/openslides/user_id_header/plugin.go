package user_id_header

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
)

// Mandatory config struct
type Config struct {
}

func CreateConfig() *Config {
	return &Config{}
}

type UserIDHeaderInsert struct {
	next http.Handler
	name string
}

// Create new plugin instance
func New(ctx context.Context, next http.Handler, config *Config, name string) (http.Handler, error) {
	return &UserIDHeaderInsert{
		next: next,
		name: name,
	}, nil
}

func extractUserID(r *http.Request) int {
	header := r.Header.Get("Authorization")
	encodedToken := strings.TrimPrefix(header, "Bearer: ")

	if header == encodedToken {
		// No token. Handle the request as public access requst.
		fmt.Println("header error: no token")
		return 0
	}

	parts := strings.Split(encodedToken, ".")
	if len(parts) != 3 {
		fmt.Println("header error: JWT partition not length 3")
		return 0
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		fmt.Println("header error: decoding token payload:", err)
		return 0
	}

	var claims map[string]any
	if err := json.Unmarshal(payload, &claims); err != nil {
		fmt.Println("header error: parsing token claims:", err)
		return 0
	}

	rawOsID, exists := claims["os_id"]
	if !exists {
		fmt.Println("header error: missing os_id in token claims")
		return 0
	}

	osID, err := strconv.Atoi(fmt.Sprintf("%v", rawOsID))
	if err != nil {
		fmt.Println("header error: invalid os_id value:", rawOsID)
		return 0
	}
	return osID
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

func (p *UserIDHeaderInsert) ServeHTTP(w http.ResponseWriter, r *http.Request) {

	// Extract User ID
	user_id := extractUserID(r)

	// Write it as a new header
	r.Header.Set(userIDHeader, fmt.Sprint(user_id))

	var flusher http.Flusher
	if f, ok := w.(http.Flusher); ok {
		flusher = f
	}

	// Pass
	p.next.ServeHTTP(&responseWriter{
		flusher:        flusher,
		ResponseWriter: w,
		userID:         fmt.Sprint(user_id),
	}, r)
}

const (
	userIDHeader string = "X-User-ID"
)
