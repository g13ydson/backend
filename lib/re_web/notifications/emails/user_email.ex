defmodule ReWeb.Notifications.UserEmail do
  @moduledoc """
  Module for building e-mails to send to users
  """
  import Swoosh.Email

  alias Re.{
    Calendars,
    Interest,
    Listing,
    User
  }

  @to String.split(Application.get_env(:re, :to), "|")
  @from Application.get_env(:re, :from)
  @frontend_url Application.get_env(:re, :frontend_url)
  @admin_email "admin@emcasa.com"
  @contato_email "contato@emcasa.com"
  @listing_path "/imoveis/"

  def notify_interest(%Interest{
        name: name,
        email: email,
        phone: phone,
        message: message,
        listing_id: listing_id,
        interest_type: interest_type,
        inserted_at: inserted_at
      }) do
    new()
    |> to(get_to_email(interest_type))
    |> from(@from)
    |> subject("Novo interesse em listagem EmCasa")
    |> html_body(
      "Nome: #{name}<br> Email: #{email}<br> Telefone: #{phone}<br> Id da listagem: #{listing_id}<br> Mensagem: #{
        message
      } <br> #{interest_type && interest_type.name}
        <br> Inserido em (UTC): #{inserted_at}"
    )
    |> text_body(
      "Nome: #{name}\n Email: #{email}\n Telefone: #{phone}\n Id da listagem: #{listing_id}<br> Mensagem: #{
        message
      } <br> #{interest_type && interest_type.name}
        <br> Inserido em (UTC): #{inserted_at}"
    )
  end

  def user_registered(%User{name: name}) do
    new()
    |> to(@to)
    |> from(@admin_email)
    |> subject("Novo usuário cadastrado")
    |> html_body("Um novo usuário realizou cadastro no EmCasa.<br>
      Nome: #{name}")
    |> text_body("Um novo usuário realizou cadastro no EmCasa.
      Nome: #{name}")
  end

  def build_url(path, param) do
    @frontend_url
    |> URI.merge(path)
    |> URI.merge(param)
    |> URI.to_string()
  end

  def listing_added_admin(%User{name: name, email: email, phone: phone}, %Listing{} = listing) do
    listing_url = build_url(@listing_path, to_string(listing.id))

    new()
    |> to(@to)
    |> from(@admin_email)
    |> subject("Um usuário cadastrou um imóvel")
    |> html_body("Nome: #{name}<br>
                  Email: #{email}<br>
                  Telefone: #{phone}<br>
                  <a href=\"#{listing_url}\">Imóvel</a><br>")
    |> text_body("Nome: #{name}
                  Email: #{email}
                  Telefone: #{phone}
                  <a href=\"#{listing_url}\">Imóvel</a>")
  end

  def listing_updated(%User{name: name, email: email}, %Listing{} = listing, changes) do
    listing_url = build_url(@listing_path, to_string(listing.id))
    {changes_html, changes_txt} = build_changes(changes)

    new()
    |> to(@to)
    |> from(@admin_email)
    |> subject("Um usuário modificou o imóvel")
    |> html_body("Nome: #{name}<br>
                  Email: #{email}<br>
                  <a href=\"#{listing_url}\">Imóvel</a><br>
                  #{changes_html}")
    |> text_body("Nome: #{name}
                  Email: #{email}
                  <a href=\"#{listing_url}\">Imóvel</a>
                  #{changes_txt}")
  end

  defp build_changes(changes) do
    {Enum.map(changes, fn {attr, value} -> "Atributo: #{attr}, novo valor: #{value}<br>" end),
     Enum.map(changes, fn {attr, value} -> "Atributo: #{attr}, novo valor: #{value}" end)}
  end

  defp get_to_email(%{name: "Agendamento online"}), do: @contato_email
  defp get_to_email(_), do: @to

  def contact_request(%{name: name, email: email, phone: phone, message: message}) do
    new()
    |> to(@to)
    |> from(@admin_email)
    |> subject("Um usuário requisitou contato pela calculadora")
    |> html_body("Nome: #{name}<br>
                  Email: #{email}<br>
                  Telefone: #{phone}<br>
                  Mensagem: #{message}")
    |> text_body("Nome: #{name}
                  Email: #{email}
                  Telefone: #{phone}
                  Mensagem: #{message}")
  end

  def notification_coverage_asked(%{
        name: name,
        email: email,
        phone: phone,
        message: message,
        user: user,
        address: address
      }) do
    new()
    |> to(@to)
    |> from(@admin_email)
    |> subject("Um usuário pediu pra ser notificado quando cobrirmos uma região")
    |> html_body("Nome: #{name || user.name}<br>
                  Email: #{email || user.email}<br>
                  Telefone: #{phone || user.phone}<br>
                  Mensagem: #{message}<br>
                  Endereço:<br>
                    Rua: #{address.street}<br>
                    Número: #{address.street_number}<br>
                    Cidade: #{address.city}<br>
                    Estado: #{address.state}<br>
                    Bairro: #{address.neighborhood}<br>")
    |> text_body("Nome: #{name || user.name}
                  Email: #{email || user.email}
                  Telefone: #{phone || user.phone}
                  Mensagem: #{message}
                  Endereço:
                    Rua: #{address.street}
                    Número: #{address.street_number}
                    Cidade: #{address.city}
                    Estado: #{address.state}
                    Bairro: #{address.neighborhood}")
  end

  def tour_appointment(%{
        wants_pictures: wants_pictures,
        wants_tour: wants_tour,
        options: options,
        user: user,
        listing: listing
      }) do
    listing_url = build_url(@listing_path, to_string(listing.id))

    new()
    |> to(@to)
    |> from(@admin_email)
    |> subject("Um usuário pediu concluir a inserção do imóvel")
    |> html_body("Nome: #{user.name}<br>
                  Telefone: #{user.phone}<br>
                  #{wants_pictures(wants_pictures)}<br>
                  #{wants_tour(wants_tour)}<br>
                  Opções de horário: #{options(options)}
                  <a href=\"#{listing_url}\">Imóvel</a><br>")
    |> text_body("Nome: #{user.name}<br>
                  Telefone: #{user.phone}<br>
                  #{wants_pictures(wants_pictures)}<br>
                  #{wants_tour(wants_tour)}<br>
                  Opções de horário: #{options(options)}
                  <a href=\"#{listing_url}\">Imóvel</a><br>")
  end

  defp wants_pictures(true), do: "Foto profissional: <b>Sim</b>"
  defp wants_pictures(false), do: "Foto profissional: <b>Não</b>"
  defp wants_tour(true), do: "Tour 3D: <b>Sim</b>"
  defp wants_tour(false), do: "Tour 3D: <b>Não</b>"

  defp options(options) do
    options
    |> Enum.map(fn %{datetime: datetime} -> Calendars.format_datetime(datetime) end)
    |> Enum.join("<br>\n")
  end

  def price_suggestion_requested(request, suggested_price) do
    new()
    |> to(@to)
    |> from(@admin_email)
    |> subject("Um usuário requisitou sugestão de preço pelo lead magnet")
    |> html_body("Nome: #{request.name}<br>
                  Email: #{request.email}<br>
                  Area: #{request.area}<br>
                  Quartos: #{request.rooms}<br>
                  Banheiros: #{request.bathrooms}<br>
                  Vagas: #{request.garage_spots}<br>
                  Rua: #{request.address.street}<br>
                  Número: #{request.address.street_number}<br>
                  #{unless request.is_covered, do: "Área fora de cobertura"}<br>
                  Preço sugerido: #{suggested_price || "Rua não coberta"}")
    |> text_body("Nome: #{request.name}
                  Email: #{request.email}
                  Area: #{request.area}
                  Quartos: #{request.rooms}
                  Banheiros: #{request.bathrooms}
                  Vagas: #{request.garage_spots}
                  Rua: #{request.address.street}
                  Número: #{request.address.street_number}
                  #{unless request.is_covered, do: "Área fora de cobertura"}
                  Preço sugerido: #{suggested_price || "Rua não coberta"}")
  end
end
