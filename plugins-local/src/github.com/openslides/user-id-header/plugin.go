package myplugin

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v4"
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

type payloadKeycloak struct {
	jwt.RegisteredClaims
	KeycloakID string `json:"sub"`
	SessionID  string `json:"sid"` // Keycloak session ID
	Email      string `json:"email"`
	Username   string `json:"preferred_username"`
	ClientName string `json:"azp"`
	OSUserID   string `json:"os_id"`
}

func extractUserID(r *http.Request) int {
	header := r.Header.Get("Authorization")
	encodedToken := strings.TrimPrefix(header, "Bearer: ")

	if header == encodedToken {
		// No token. Handle the request as public access requst.
		return 0
	}

	token, _, err := new(jwt.Parser).ParseUnverified(header, &payloadKeycloak{})
	if err != nil {
		fmt.Println("parsing token: %w", err)
		return 0
	}

	user_id, ok := token.Header["os_id"].(int)
	if !ok {
		fmt.Println("missing user id in token header")
		return 0
	}
	return user_id
}

func (p *UserIDHeaderInsert) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Extract User ID
	user_id := extractUserID(r)

	// Write it as a new header
	r.Header.Set("X-User-ID", fmt.Sprint(user_id))

	// Pass
	p.next.ServeHTTP(w, r)
}
