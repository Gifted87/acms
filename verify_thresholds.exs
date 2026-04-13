# Verification script
node_head = CMS.NodeHead.new(Nx.tensor([0.1, 0.2]), "test_model")
if node_head.relevance_threshold == 0.4 do
  IO.puts "Verification Passed: Default threshold is 0.4"
else
  IO.puts "Verification Failed: Default threshold is #{node_head.relevance_threshold}"
  System.halt(1)
end
