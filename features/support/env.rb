Before do
  ENV['TESTING'] = 'true'
end

Before do
  @aruba_timeout_seconds = 560
end

After do
  FakeHeroku.clear!
end

After do
  FileUtils.rm_rf('test_project')
end
