module Awetestlib
  VERSION      = "1.2.2"
  VERSION_DATE = "2015-07-10"
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
