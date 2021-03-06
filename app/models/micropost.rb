class Micropost < ActiveRecord::Base

	belongs_to :user
	has_and_belongs_to_many :in_reply_to_users, join_table: "replies", 
	class_name: "User", association_foreign_key: :in_reply_to_id
	default_scope -> { order('microposts.created_at DESC') }
	validates :user_id, presence: true
	validates :content, presence: true, length: { maximum:  140 }

	before_save :set_in_reply_to

	def self.REPLY_REGEX
		/[@][\w\-\.]+/
	end

	# Returns microposts from the users being followed by the given user.
	def self.from_users_followed_by(user)
		followed_user_ids = "SELECT followed_id FROM relationships
		WHERE follower_id = :user_id"
		where("user_id IN (#{followed_user_ids}) OR user_id = :user_id",
			user_id: user)

	end

	def self.including_replies_to(user)
		recipient_user_ids = "SELECT in_reply_to_id FROM replies
		WHERE microposts.id = replies.micropost_id"
		where(":user_id IN (#{recipient_user_ids})", user_id: user)
	end

	def self.including_replies_to_users_followed_by(user)
		followed_user_ids = "SELECT followed_id FROM relationships
		WHERE follower_id = :user_id"
		self.joins(:in_reply_to_users).where("replies.in_reply_to_id IN (#{followed_user_ids})",
			user_id: user)
	end

	def reply?
		content.scan(Micropost.REPLY_REGEX).each do |reply_tag|
			username = reply_tag[1..-1]
			if User.find_by(username: username)
				return true
			end			
		end
		false
	end	

	private

		def set_in_reply_to
			content.scan(Micropost.REPLY_REGEX).each do |reply_tag|
				username = reply_tag[1..-1]
				user = User.find_by(username: username)
				in_reply_to_users << user if user
			end
		end

end
