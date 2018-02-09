module Awetestlib
  VERSION = "2.0.0"
  VERSION_DATE = "2015-06-20"
  if Dir.exists?('.git')
    require 'git'
    git      = Git.open(Dir.pwd)
    branch   = git.current_branch
    commit   = git.gblob(branch).log(5).first
    BRANCH   = branch
    SHA      = commit.sha
    SHA_DATE = commit.date
  end
end
