Feature: User Creates Report
  In order to report environmental problems around me
  As a logged-in user
  I want to create a new report with location and photo

  Scenario: User successfully creates a report with photo and location
    Given I am logged in as "rifat@gmail.com"
    And I am on the "Buat Laporan" page
    When I fill in "judul" with "Tumpukan sampah di pinggir sungai"
    And I fill in "deskripsi" with "Banyak sampah plastik menumpuk di dekat jembatan."
    And I fill in "lokasi_text" with "Jl. Jembatan Hijau No. 10"
    And I allow the app to access my location
    And my current coordinates are "lat=-6.200000" and "lng=106.816666"
    And I attach the file "/path/to/foto-sampah.jpg" to "foto"
    And I press "Kirim Laporan"
    Then a new report should be stored with:
      | judul         | Tumpukan sampah di pinggir sungai |
      | status        | Pending                           |
      | email_pelapor | rifat@gmail.com                   |
    And I should be redirected to "Daftar Laporan Saya"

  Scenario: User fails to create report when required fields are empty
    Given I am logged in as "rifat@gmail.com"
    And I am on the "Buat Laporan" page
    When I leave "judul" empty
    And I leave "deskripsi" empty
    And I press "Kirim Laporan"
    Then I should see "The judul field is required."
    And I should see "The deskripsi field is required."
    And no new report should be stored
