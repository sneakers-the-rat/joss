require 'rails_helper'

RSpec.describe BadgesController, type: :controller do
  render_views

  describe "GET #edited_by" do
    let(:editor) { create(:editor, login: "editor-jane") }

    # Pulls the count out of the SVG's aria-label, which is rendered as
    # `aria-label="JOSS Editor: 3"` by app/views/badges/badge.svg.erb.
    def rendered_count
      response.body[/aria-label="JOSS Editor: (\d+)"/, 1]
    end

    it "renders an SVG badge for the editor" do
      get :edited_by, params: { editor: editor.login }, format: :svg

      expect(response).to be_successful
      expect(response.content_type).to include("image/svg+xml")
      expect(response.body).to include('aria-label="JOSS Editor:')
    end

    it "counts papers edited by the given editor" do
      create_list(:accepted_paper, 3, editor: editor)
      get :edited_by, params: { editor: editor.login }, format: :svg

      expect(rendered_count).to eq("3")
    end

    it "counts papers in any state, including rejected and retracted" do
      create(:accepted_paper,  editor: editor)
      create(:rejected_paper,  editor: editor)
      create(:retracted_paper, editor: editor)
      get :edited_by, params: { editor: editor.login }, format: :svg

      expect(rendered_count).to eq("3")
    end

    it "returns 0 for an editor with no papers" do
      get :edited_by, params: { editor: editor.login }, format: :svg

      expect(rendered_count).to eq("0")
    end

    it "does not count papers edited by other editors" do
      other = create(:editor, login: "someone-else")
      create_list(:accepted_paper, 2, editor: other)
      create(:accepted_paper, editor: editor)
      get :edited_by, params: { editor: editor.login }, format: :svg

      expect(rendered_count).to eq("1")
    end

    it "returns 0 for an unknown editor login" do
      get :edited_by, params: { editor: "no-such-editor" }, format: :svg

      expect(rendered_count).to eq("0")
    end

    it "matches editor login case-insensitively" do
      create(:accepted_paper, editor: editor)
      get :edited_by, params: { editor: editor.login.upcase }, format: :svg

      expect(rendered_count).to eq("1")
    end

    it "tolerates a leading @ on the editor login" do
      create(:accepted_paper, editor: editor)
      get :edited_by, params: { editor: "@#{editor.login}" }, format: :svg

      expect(rendered_count).to eq("1")
    end
  end
end
