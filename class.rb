require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User

  attr_accessor :id, :fname, :lname

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def create
    raise "#{self} already in database!" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users(fname, lname)
      VALUES
        (?, ?)
      SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database!" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end

  def save
    if @id
      update
    else
      create
    end
  end

  def self.find_by_id(id)
    users = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
      SQL
    return nil if users.length == 0
    User.new(users.first)
  end

  def self.find_by_name(fname, lname)
    users = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ?
      AND
        lname = ?
      SQL
    return nil if users.length == 0
    User.new(users.first)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    users = QuestionsDatabase.instance.execute(<<-SQL, @id)
    SELECT
      CAST(COUNT(question_likes.users_id) AS FLOAT) / COUNT(DISTINCT questions.id)
    FROM
      questions
    LEFT OUTER JOIN
      question_likes
    ON
      questions.id = question_likes.questions_id
    WHERE
      questions.users_id = ?
    SQL

    users.first.values.first
  end

end



class Question

  attr_accessor :id, :title, :body, :users_id

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @users_id = options['users_id']
  end

  def self.find_by_id(id)
    users = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
      SQL
    return nil if users.length == 0
    Question.new(users.first)
  end

  def self.find_by_author_id(users_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, users_id)
      SELECT
        *
      FROM
        questions
      WHERE
        users_id = ?
      SQL
    return nil if users.length == 0
    users.map { |user| Question.new(user) }
  end

  def author
    User.find_by_id(@id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

end


class QuestionFollow

  attr_accessor :id, :users_id, :questions_id

  def initialize(options)
    @id = options['id']
    @users_id = options['users_id']
    @questions_id = options['questions_id']
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_follows
    WHERE
      id = ?
    SQL
    return nil if data.length == 0
    QuestionFollow.new(data.first)
  end

  def self.followers_for_question_id(questions_id)
    user_ids = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
    SELECT
      users.id, users.fname, users.lname
    FROM
      users AS users
    JOIN
      question_follows AS question_follows
    ON
      question_follows.users_id = users.id
    WHERE
      question_follows.questions_id = ?
    SQL
    # p user_ids
    return nil if user_ids.length == 0
    user_ids.map {|user| User.new(user)}
  end

  def self.followed_questions_for_user_id(user_id)
    user_ids = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      questions.id, questions.title, questions.users_id
    FROM
      questions AS questions
    JOIN
      question_follows AS question_follows
    ON
      question_follows.questions_id = questions.id
    WHERE
      question_follows.users_id = ?
    SQL
    # p user_ids
    return nil if user_ids.length == 0
    user_ids.map {|user| Question.new(user)}
  end

  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, questions.title, questions.users_id
      FROM
        questions
      LEFT OUTER JOIN
        question_follows
      ON
        question_follows.questions_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.users_id) DESC
      LIMIT ?
    SQL

    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

end

class Reply

  attr_accessor :id, :questions_id, :parent_id, :users_id, :body

  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @parent_id = options['parent_id']
    @users_id = options['users_id']
    @body = options['body']
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil if data.length == 0
    Reply.new(data.first)
  end

  def self.find_by_user_id(users_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, users_id)
      SELECT
        *
      FROM
        replies
      WHERE
        users_id = ?
      SQL
    return nil if users.length == 0
    users.map { |user| Reply.new(user) }
  end

  def self.find_by_question_id(questions_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, questions_id)
      SELECT
        *
      FROM
        replies
      WHERE
        questions_id = ?
      SQL
    return nil if users.length == 0
    users.map { |user| Reply.new(user) }
  end

  def author
    User.find_by_id(@users_id)
  end

  def question
    Question.find_by_id(@questions_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_id)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    return nil if children.empty?
    children.map {|child| Reply.new(child)}
  end

end

class QuestionLike

  attr_accessor :id, :questions_id, :users_id

  def initialize(options)
    @id = options['id']
    @questions_id = options['questions_id']
    @users_id = options['users_id']
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    return nil if data.length == 0
    QuestionLike.new(data.first)
  end

  def self.likers_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, users.fname, users.lname
      FROM
        question_likes
      JOIN
        users
      ON
        question_likes.users_id = users.id
      WHERE
        question_likes.questions_id = ?
    SQL

    return nil if data.empty?
    data.map { |user| User.new(user) }
  end

  def self.num_likes_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(questions_id)
    FROM
      question_likes
    WHERE
      questions_id = ?
    SQL
    data.first.values.first
  end

  def self.liked_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, questions.title, questions.body, questions.users_id
      FROM
        question_likes
      JOIN
        questions
      ON
        question_likes.questions_id = questions.id
      WHERE
        question_likes.users_id = ?
    SQL

    return nil if data.empty?
    data.map { |user| Question.new(user) }
  end

  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, questions.title, questions.users_id
      FROM
        questions
      LEFT OUTER JOIN
        question_likes
      ON
        question_likes.questions_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_likes.users_id) DESC
      LIMIT ?
    SQL

    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

end
