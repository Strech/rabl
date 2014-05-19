# Lives in <rabl>/test/integration/posts_controller_test.rb
# Symlinked to fixture applications

begin # Padrino
  require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')
rescue LoadError # Rails
  require File.expand_path(File.dirname(__FILE__) + '/../test_helper.rb')
end

context "PostsController" do
  helper(:json_output) { JSON.parse(last_response.body) }

  setup do
    create_users!
    Post.delete_all
    @post1 = Post.create(:title => "Foo", :body => "Bar", :user_id => @user1.id)
  end

  context "filter" do
    context "only title" do
      setup do
        get "/posts/#{@post1.id}/filter?filter=title"
        json_output['post']
      end

      asserts("contains post title") { topic['title'] }.equals { @post1.title }
      asserts("contains post body")  { topic['body'] }.equals { nil }
    end

    context "only body" do
      setup do
        get "/posts/#{@post1.id}/filter?filter=body"
        json_output['post']
      end
      asserts("contains post title") { topic['title'] }.equals { nil }
      asserts("contains post body")  { topic['body'] }.equals { @post1.body }
    end

    context "only user_id,body" do
      setup do
        get "/posts/#{@post1.id}/filter?filter=uid,body"
        json_output['post']
      end
      asserts("contains post title") { topic['title'] }.equals { nil }
      asserts("contains post body")  { topic['body'] }.equals { @post1.body }
      asserts("contains post user_id as uid")  { topic['uid'] }.equals { @post1.user_id }
    end

    context "default" do
      setup do
        get "/posts/#{@post1.id}/filter?filter=default"
        json_output['post']
      end
      asserts("contains post title") { topic['title'] }.equals { @post1.title }
      asserts("contains post body")  { topic['body'] }.equals { @post1.body }
    end

    context "all" do
      setup do
        get "/posts/#{@post1.id}/filter?filter=all"
        json_output['post']
      end
      asserts("contains post title") { topic['title'] }.equals { @post1.title }
      asserts("contains post body")  { topic['body'] }.equals { @post1.body }
      asserts("contains post user_id as uid")  { topic['uid'] }.equals { @post1.user_id }
      asserts("contains post user => [email, username is_admin phones]")  { topic['user'].keys }.equals { %w[email username is_admin phones] }

      asserts("contains post user => phone => [formatted, is_primary]")  {
        topic['user']['phones']
      }.equals {
        @user1.phone_numbers.map do |phone|
          Hash[%w[formatted is_primary name].map do |attr|
            [attr, phone.send(attr)]
          end]
        end
      }
    end

    context "all" do
      setup do
        get "/posts/#{@post1.id}/filter?filter=all"
        json_output['post']
      end
      asserts("contains post title") { topic['title'] }.equals { @post1.title }
      asserts("contains post body")  { topic['body'] }.equals { @post1.body }
      asserts("contains post user_id as uid")  { topic['uid'] }.equals { @post1.user_id }
      asserts("contains post user => [email, username is_admin phones]")  { topic['user'].keys }.equals { %w[email username is_admin phones] }

      asserts("contains post user => phone => [formatted, is_primary]")  {
        topic['user']['phones']
      }.equals {
        @user1.phone_numbers.map do |phone|
          Hash[%w[formatted is_primary name].map do |attr|
            [attr, phone.send(attr)]
          end]
        end
      }
    end
  end # filter action, json

end
