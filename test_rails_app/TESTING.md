# Testing TheMechanic2 Engine

## Server Status

The Rails test application is currently running on port 3005.

## Access the Engine

The TheMechanic2 engine is mounted and accessible at:

**http://localhost:3005/mechanic**

## What You Can Do

1. **View the UI**: Open the URL above in your browser to see the benchmarking interface
2. **Test Benchmarking**: Enter two Ruby code snippets to compare their performance
3. **API Endpoints**: The following endpoints are available:
   - `POST /mechanic/validate` - Validate code without running
   - `POST /mechanic/run` - Execute benchmark comparison
   - `POST /mechanic/export` - Export results in JSON or Markdown

## Stopping the Server

To stop the server, run:
```bash
kill $(cat tmp/pids/server.pid)
```

## Restarting the Server

If you need to restart:
```bash
cd test_rails_app
bundle exec rails server -p 3005
```

## Testing the Engine

Try benchmarking these example snippets:

**Code A:**
```ruby
(1..1000).to_a.map { |n| n * 2 }
```

**Code B:**
```ruby
Array.new(1000) { |n| (n + 1) * 2 }
```

The engine will show you which code is faster and by how much!
