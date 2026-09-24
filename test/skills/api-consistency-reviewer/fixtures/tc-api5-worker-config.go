// Package config loads the queue worker's YAML configuration file.
//
// Operators maintain their own worker.yaml files; the loader is shared by
// every deployment of the worker.
package config

import (
	"errors"
	"fmt"
	"os"
	"time"

	"gopkg.in/yaml.v3"
)

type Config struct {
	BrokerURL       string        `yaml:"broker_url"`
	QueueName       string        `yaml:"queue_name"`
	Concurrency     int           `yaml:"concurrency"`
	PollInterval    time.Duration `yaml:"poll_interval"`
	VisibilityTTL   time.Duration `yaml:"visibility_ttl"`
	MetricsAddr     string        `yaml:"metrics_addr"`
	ShutdownTimeout time.Duration `yaml:"shutdown_timeout"`
	// BEGIN CHANGE UNDER REVIEW
	DeadLetterQueue string `yaml:"dead_letter_queue"`
	// END CHANGE UNDER REVIEW
}

func (c *Config) applyDefaults() {
	if c.Concurrency == 0 {
		c.Concurrency = 4
	}
	if c.PollInterval == 0 {
		c.PollInterval = 2 * time.Second
	}
	if c.VisibilityTTL == 0 {
		c.VisibilityTTL = 30 * time.Second
	}
	if c.MetricsAddr == "" {
		c.MetricsAddr = ":9090"
	}
	if c.ShutdownTimeout == 0 {
		c.ShutdownTimeout = 15 * time.Second
	}
}

func (c *Config) validate() error {
	if c.BrokerURL == "" {
		return errors.New("config: broker_url is required")
	}
	if c.QueueName == "" {
		return errors.New("config: queue_name is required")
	}
	if c.Concurrency < 1 {
		return fmt.Errorf("config: concurrency must be >= 1, got %d", c.Concurrency)
	}
	// BEGIN CHANGE UNDER REVIEW
	if c.DeadLetterQueue == "" {
		return errors.New("config: dead_letter_queue is required")
	}
	// END CHANGE UNDER REVIEW
	return nil
}

// Load reads, defaults and validates the config file at path.
func Load(path string) (*Config, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("config: read %s: %w", path, err)
	}
	var c Config
	if err := yaml.Unmarshal(raw, &c); err != nil {
		return nil, fmt.Errorf("config: parse %s: %w", path, err)
	}
	c.applyDefaults()
	if err := c.validate(); err != nil {
		return nil, err
	}
	return &c, nil
}
