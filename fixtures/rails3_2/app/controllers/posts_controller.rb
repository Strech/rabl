class PostsController < ApplicationController
  respond_to :json, :xml, :html, :rabl_test_v1

  def index
    @posts = Post.all(:order => "id ASC")
  end

  def show
    @post = Post.find(params[:id])
  end

  def renderer
    post = Post.find(params[:id])
    render json: Rabl.render(post, 'posts/renderer', view_path: 'app/views', format: :json, scope: view_context)
  end

  def filter
    _filter = params[:filter].to_s.split(',')
    if _filter.include? 'all'
      @filter = {}
      @filter_mode = Rabl::Filter::ALL
    elsif _filter.include? 'default'
      @filter = _filter - ['default']
      @filter_mode = Rabl::Filter::DEFAULT
    else
      @filter = _filter
      @filter_mode = Rabl::Filter::CUSTOM
    end
    post = Post.find(params[:id])
    render json: Rabl.render(
      post, 'posts/filter',
      view_path: 'app/views', format: :json,
      scope: view_context
    )
  end
end
