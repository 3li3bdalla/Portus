# frozen_string_literal: true

class TagsController < ApplicationController
  include Deletable

  def show
    @tag = Tag.find(params[:id])
    authorize @tag

    @names = Tag.where(digest: @tag.digest).sort.map(&:name)
    @vulnerabilities = @tag.fetch_vulnerabilities
  end

  # Removes all tags that match the digest of the tag with the given ID.
  # Moreover, it will also remove the image if it's left empty after removing
  # the tags.
  def destroy
    tag = Tag.find(params[:id])
    authorize tag

    # And now remove the tag by the digest. If the repository containing said
    # tags becomes empty after that, remove it too.
    repo = tag.repository
    if tag.delete_by_digest!(current_user)
      if repo.tags.empty?
        repo.delete_by!(current_user)
        flash[:notice] = "Repository removed with all its tags"
      end
      head :ok
    else
      head :internal_server_error
    end
  end
end
