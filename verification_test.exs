# verification_test.exs
# Run with: mix run verification_test.exs

require Logger

path = Path.expand("verify_fixes")
{:ok, root_id} = CMS.Ingestion.Crawler.crawl(path)

IO.puts "Ingestion complete for #{path}. Root ID: #{root_id}"
