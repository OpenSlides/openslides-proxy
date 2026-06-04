package myplugin

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

type UserIDHeaderInsert struct {
	next         http.Handler
	name         string
	sourceHeader string
	targetHeader string
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
		return 0
	}

	parts := strings.Split(encodedToken, ".")
	if len(parts) != 3 {
		fmt.Println("JWT partition not length 3")
		return 0
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		fmt.Println("decoding token payload:", err)
		return 0
	}

	var claims map[string]interface{}
	if err := json.Unmarshal(payload, &claims); err != nil {
		fmt.Println("parsing token claims:", err)
		return 0
	}

	osID, ok := claims["os_id"].(float64)
	if !ok {
		fmt.Println("missing or invalid os_id in token claims")
		return 0
	}
	return int(osID)
}

func (p *UserIDHeaderInsert) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Extract User ID
	user_id := extractUserID(r)

	// Write it as a new header
	r.Header.Set("X-User-ID", fmt.Sprint(user_id))

	// Pass
	p.next.ServeHTTP(w, r)
}
