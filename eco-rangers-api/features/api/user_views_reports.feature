Feature: User Views Own Reports
  In order to track the handling status of my reports
  As a logged-in user
  I want to view the list of my reports and see their details

  # US-04: Lihat daftar laporan

  Scenario: User views the list of his own reports
    Given I am logged in as "rifat@gmail.com"
    And there are reports created by "rifat@gmail.com":
      | judul                              | status   |
      | Tumpukan sampah di pinggir sungai  | Pending  |
    When I navigate to "Daftar Laporan Saya"
    Then I should see "Tumpukan sampah di pinggir sungai"
    And I should see the status for each report

  # US-05: Lihat detail laporan

  Scenario: User views the detail of a specific report
    Given I am logged in as "rifat@gmail.com"
    And there is a report with:
      | judul        | Tumpukan sampah di pinggir sungai               |
      | deskripsi    | Banyak sampah plastik menumpuk di dekat jembatan|
      | lokasi_text  | Jl. Jembatan Hijau No. 10                       |
      | status       | Pending                                         |
    When I navigate to "Daftar Laporan Saya"
    And I follow "Tumpukan sampah di pinggir sungai"
    Then I should see "Banyak sampah plastik menumpuk di dekat jembatan"
    And I should see "Jl. Jembatan Hijau No. 10"
    And the report status should be "Pending"
    And I should see the report photo if available
