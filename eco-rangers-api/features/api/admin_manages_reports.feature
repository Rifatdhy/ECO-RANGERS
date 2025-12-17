Feature: Admin Manages Reports
  In order to handle all incoming environmental reports
  As an administrator
  I want to view all reports, update their status, and delete invalid ones

  # US-06: Admin melihat semua laporan

  Scenario: Admin views all reports
    Given I am logged in as admin "admin@gmail.com"
    And there are reports in the system:
      | judul                              | status   |
      | Tumpukan sampah di pinggir sungai  | Pending  |
    When I navigate to "Dashboard Admin"
    And I go to "Daftar Semua Laporan"
    Then I should see "Tumpukan sampah di pinggir sungai"
    And I should see their current status

  # US-07: Admin mengubah status laporan

  Scenario: Admin updates report status from Pending to Diproses
    Given I am logged in as admin "admin@gmail.com"
    And there is a report with:
      | judul   | Tumpukan sampah di pinggir sungai |
      | status  | Pending                           |
    When I navigate to "Daftar Semua Laporan"
    And I open the detail for "Tumpukan sampah di pinggir sungai"
    And I select "Diproses" from "status"
    And I press "Update Status"
    Then the report status should be "Diproses"
    And I should see "Status laporan berhasil diubah"

  Scenario: Admin updates report status from Diproses to Selesai
    Given I am logged in as admin "admin@gmail.com"
    And there is a report with:
      | judul   | Tumpukan sampah di pinggir sungai |
      | status  | Diproses                |
    When I navigate to "Daftar Semua Laporan"
    And I open the detail for "Tumpukan sampah di pinggir sungai"
    And I select "Selesai" from "status"
    And I press "Update Status"
    Then the report status should be "Selesai"
    And I should see "Status laporan berhasil diubah"
