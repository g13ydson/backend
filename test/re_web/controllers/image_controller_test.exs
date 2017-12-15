defmodule ReWeb.ListingImageControllerTest do
  use ReWeb.ConnCase

  import Re.Factory

  setup %{conn: conn} do
    user = insert(:user)
    {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user)
    conn =
      conn
      |> put_req_header("accept", "application/json")

    authenticated_conn = put_req_header(conn, "authorization", "Token #{jwt}")
    {:ok, authenticated_conn: authenticated_conn, unauthenticated_conn: conn}
  end

  test "lists all images for a listing", %{authenticated_conn: conn} do
    address = insert(:address)
    image = insert(:image)
    listing = insert(:listing, images: [image], address: address)

    conn = get conn, listing_image_path(conn, :index, listing)
    assert json_response(conn, 200)["images"] == [
      %{
        "filename" => image.filename,
        "id" => image.id,
        "position" => image.position
      }
    ]
  end

  test "don't list images for unauthenticated requests", %{unauthenticated_conn: conn} do
    address = insert(:address)
    image = insert(:image)
    listing = insert(:listing, images: [image], address: address)

    conn = get conn, listing_image_path(conn, :index, listing)
    json_response(conn, 403)
  end
end