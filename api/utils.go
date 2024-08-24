package api

import (
	"encoding/json"
	"errors"
	"github.com/evilsocket/islazy/log"
	"net/http"
	"strconv"
	"strings"
)

var (
	ErrEmpty        = errors.New("")
	ErrUnauthorized = errors.New("unauthorized")
)

func clientIP(r *http.Request) string {
	address := strings.Split(r.RemoteAddr, ":")[0]
	if forwardedFor := r.Header.Get("X-Forwarded-For"); forwardedFor != "" {
		address = forwardedFor
	}
	// https://support.cloudflare.com/hc/en-us/articles/206776727-What-is-True-Client-IP-
	if trueClient := r.Header.Get("True-Client-IP"); trueClient != "" {
		address = trueClient
	}
	// handle multiple IPs case
	return strings.Trim(strings.Split(address, ",")[0], " ")
}

func reqToken(r *http.Request) string {
	keys := r.URL.Query()
	token := keys.Get("token")
	if token != "" {
		return token
	}
	bearerToken := r.Header.Get("Authorization")
	if parts := strings.Split(bearerToken, " "); len(parts) == 2 {
		return parts[1]
	}
	return ""
}

func pageNum(r *http.Request) (int, error) {
	pageParam := r.URL.Query().Get("p")
	if pageParam == "" {
		pageParam = "1"
	}
	return strconv.Atoi(pageParam)
}

func JSON(w http.ResponseWriter, statusCode int, data interface{}) {
	js, err := json.Marshal(data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	if sent, err := w.Write(js); err != nil {
		log.Error("error sending response: %v", err)
	} else {
		log.Debug("sent %d bytes of json response", sent)
	}
}

func ERROR(w http.ResponseWriter, statusCode int, err error) {
	if err != nil {
		JSON(w, statusCode, struct {
			Error string `json:"error"`
		}{
			Error: err.Error(),
		})
		return
	}
	JSON(w, http.StatusBadRequest, nil)
}
