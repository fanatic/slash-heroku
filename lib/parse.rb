module Parse
 class Releases
   attr_reader :releases, :deploys
   def initialize(releases, deploys)
     @releases = releases
     @deploys = deploys
   end

   def all
     releases.each_with_object(Array.new) do |release_info, array|
       array << Release.new(release_info, GitHubRefs.new(deploys))
     end
   end
 end

 class GitHubRefs
   attr_reader :deploy_list

   def initialize(deploy_list)
     @deploy_list = deploy_list
   end

   def by_sha(sha)
     sha_and_ref_hash[sha]
   end

   def sha_and_ref_hash
     deploy_list.each_with_object(Hash.new(0)) do |deploy, hash|
       sha = deploy["sha"]
       shortened_sha = sha[0..6]
       ref = deploy["ref"]
       ref = shortened_sha if sha == ref
       hash[shortened_sha] = ref
     end
   end
 end

 class Release
   attr_reader :release_info, :github_refs

   def initialize(release_info, github_refs)
     @release_info = release_info
     @github_refs = github_refs
   end

   def sha
     sha = description.gsub("Deploy ", "")
     sha =~ /\A\h{7,40}\z/ ? sha[0..6] : nil
   end

   def description
     release_info["description"]
   end

   def ref
     return unless sha
     github_refs.by_sha(sha)
   end
 end
end


