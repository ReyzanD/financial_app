-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 03, 2025 at 12:07 AM
-- Server version: 8.0.30
-- PHP Version: 8.3.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `financial_db_232143`
--

-- --------------------------------------------------------

--
-- Table structure for table `ai_recommendations_232143`
--

CREATE TABLE `ai_recommendations_232143` (
  `recommendation_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) NOT NULL,
  `type_232143` enum('budget_optimization','saving_opportunity','spending_alert','investment_suggestion','debt_management','location_saving') NOT NULL,
  `title_232143` varchar(255) NOT NULL,
  `description_232143` text NOT NULL,
  `action_items_232143` json DEFAULT NULL,
  `estimated_savings_232143` decimal(15,2) DEFAULT NULL,
  `impact_score_232143` int DEFAULT NULL,
  `urgency_232143` enum('low','medium','high','critical') DEFAULT 'medium',
  `related_categories_232143` json DEFAULT NULL,
  `related_locations_232143` json DEFAULT NULL,
  `data_sources_232143` json DEFAULT NULL,
  `is_read_232143` tinyint(1) DEFAULT '0',
  `is_applied_232143` tinyint(1) DEFAULT '0',
  `applied_date_232143` timestamp NULL DEFAULT NULL,
  `user_feedback_232143` int DEFAULT NULL,
  `model_version_232143` varchar(50) DEFAULT NULL,
  `confidence_score_232143` decimal(3,2) DEFAULT NULL,
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at_232143` timestamp NULL DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Table structure for table `bill_payments_232143`
--

CREATE TABLE `bill_payments_232143` (
  `payment_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `bill_id_232143` varchar(36) NOT NULL,
  `user_id_232143` varchar(36) NOT NULL,
  `amount_paid_232143` decimal(15,2) NOT NULL,
  `payment_date_232143` date NOT NULL,
  `payment_method_232143` varchar(50) DEFAULT NULL,
  `transaction_id_232143` varchar(36) DEFAULT NULL,
  `status_232143` enum('paid','pending','failed') DEFAULT 'paid',
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `budgets_232143`
--

CREATE TABLE `budgets_232143` (
  `budget_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) NOT NULL,
  `category_id_232143` varchar(36) DEFAULT NULL,
  `amount_232143` decimal(15,2) NOT NULL,
  `period_232143` enum('daily','weekly','monthly','yearly') NOT NULL,
  `period_start_232143` date NOT NULL,
  `period_end_232143` date NOT NULL,
  `spent_amount_232143` decimal(15,2) DEFAULT '0.00',
  `rollover_enabled_232143` tinyint(1) DEFAULT '0',
  `alert_threshold_232143` int DEFAULT '80',
  `is_active_232143` tinyint(1) DEFAULT '1',
  `recommended_amount_232143` decimal(15,2) DEFAULT NULL,
  `recommendation_reason_232143` text,
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `remaining_amount_232143` decimal(15,2) GENERATED ALWAYS AS ((`amount_232143` - `spent_amount_232143`)) STORED
) ;

-- --------------------------------------------------------

--
-- Table structure for table `categories_232143`
--

CREATE TABLE `categories_232143` (
  `category_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) DEFAULT NULL,
  `name_232143` varchar(100) NOT NULL,
  `type_232143` enum('income','expense','transfer') NOT NULL,
  `color_232143` varchar(7) DEFAULT '#3498db',
  `icon_232143` varchar(50) DEFAULT 'receipt',
  `budget_limit_232143` decimal(15,2) DEFAULT NULL,
  `budget_period_232143` enum('daily','weekly','monthly','yearly') DEFAULT 'monthly',
  `is_fixed_232143` tinyint(1) DEFAULT '0',
  `keywords_232143` json DEFAULT NULL,
  `location_patterns_232143` json DEFAULT NULL,
  `parent_category_id_232143` varchar(36) DEFAULT NULL,
  `display_order_232143` int DEFAULT '0',
  `is_system_default_232143` tinyint(1) DEFAULT '0',
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `categories_232143`
--

INSERT INTO `categories_232143` (`category_id_232143`, `user_id_232143`, `name_232143`, `type_232143`, `color_232143`, `icon_232143`, `budget_limit_232143`, `budget_period_232143`, `is_fixed_232143`, `keywords_232143`, `location_patterns_232143`, `parent_category_id_232143`, `display_order_232143`, `is_system_default_232143`, `created_at_232143`, `updated_at_232143`) VALUES
('07f2295f-8244-49ab-a509-ae260f059f7f', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Food & Dining', 'expense', '#FF6B6B', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('0b8b6149-8a68-4f54-bd5b-b4149ea041fc', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Utilities', 'expense', '#96CEB4', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:04:15', '2025-10-29 11:04:15'),
('15c77de5-368f-45ea-9c30-8942eb3a38ab', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Salary', 'income', '#FFEAA7', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:04:15', '2025-10-29 11:04:15'),
('1642a251-8116-47cc-b4d4-714bef117bac', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Food & Dining', 'expense', '#FF6B6B', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:04:15', '2025-10-29 11:04:15'),
('1fb8708f-8815-4773-995f-7b6836ebac8a', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Hiburan', 'expense', '#34495e', 'movie', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('270c05ea-e502-4604-8af4-a5103002b16d', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Investasi', 'income', '#27ae60', 'trending_up', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('280ab04c-5f4b-49a2-bd4a-8b07cdc64519', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Freelance', 'income', '#1abc9c', 'computer', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('2b52b766-5ef9-438d-9f68-da359a7d0f8c', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Transportation', 'expense', '#4ECDC4', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:04:15', '2025-10-29 11:04:15'),
('2dcc40fb-542c-4a35-a376-146fded45084', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Gaji', 'income', '#2ecc71', 'work', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('433e63f6-5912-4aae-8174-ecfbeb36db13', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Pendidikan', 'expense', '#2980b9', 'school', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('434194bf-780e-4602-9652-29705ada8c47', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Tabungan', 'expense', '#16a085', 'savings', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('43b060fd-c965-4b17-960d-f915bfbe0ddd', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Freelance', 'income', '#DDA0DD', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('474e9023-5038-41c3-9feb-a0c04b7fbf1e', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Transportasi', 'expense', '#f39c12', 'directions_car', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('49a07475-f591-42d8-8c7e-90a89a0f492a', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Salary', 'income', '#FFEAA7', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:05:35', '2025-10-29 11:05:35'),
('4dc0f2a3-7362-4300-b761-3966d43baff5', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Belanja', 'expense', '#9b59b6', 'shopping_cart', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('4e53ab9c-0d1c-44ca-a136-0dd4016d692f', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Investasi', 'income', '#27ae60', 'trending_up', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('501116b3-b087-4ffc-97d8-b8f4597fa21e', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Hiburan', 'expense', '#34495e', 'movie', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('63fb57d5-8c51-46d5-bab7-ac56dc5ff038', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Transportation', 'expense', '#4ECDC4', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:05:35', '2025-10-29 11:05:35'),
('69f68018-60c3-4944-9bde-90662cac8e9b', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Entertainment', 'expense', '#45B7D1', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:04:15', '2025-10-29 11:04:15'),
('718f68ca-ee21-42a2-a866-df59caa911cc', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Freelance', 'income', '#1abc9c', 'computer', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('72c3bb6b-fbf5-4e02-9f55-252711534f81', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Makanan & Minuman', 'expense', '#e74c3c', 'restaurant', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('757ffc00-d2e1-4510-947e-51a71f6bf1ed', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Gaji', 'income', '#2ecc71', 'work', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('7aeb538d-39fe-4bc4-aabc-812bfebdffdb', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Freelance', 'income', '#DDA0DD', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:05:35', '2025-10-29 11:05:35'),
('7e1d6d5b-3934-4695-b280-c2c88be52b8d', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Entertainment', 'expense', '#45B7D1', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('80805e4a-a607-4140-86f6-aa22c451f258', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Transportasi', 'expense', '#f39c12', 'directions_car', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('912f645e-cd59-404b-9314-58a1a4d68398', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Freelance', 'income', '#DDA0DD', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:04:15', '2025-10-29 11:04:15'),
('94eaf908-a8a5-4fe4-90d9-d75102134414', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Transportation', 'expense', '#4ECDC4', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('97b8b9b8-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Gaji', 'income', '#2ecc71', 'work', NULL, 'monthly', 0, NULL, NULL, NULL, 1, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c010-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Investasi', 'income', '#27ae60', 'trending_up', NULL, 'monthly', 0, NULL, NULL, NULL, 2, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c0cc-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Freelance', 'income', '#1abc9c', 'computer', NULL, 'monthly', 0, NULL, NULL, NULL, 3, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c12f-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Makanan & Minuman', 'expense', '#e74c3c', 'restaurant', NULL, 'monthly', 0, NULL, NULL, NULL, 4, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c18a-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Transportasi', 'expense', '#f39c12', 'directions_car', NULL, 'monthly', 0, NULL, NULL, NULL, 5, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c1e7-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Belanja', 'expense', '#9b59b6', 'shopping_cart', NULL, 'monthly', 0, NULL, NULL, NULL, 6, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c23c-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Hiburan', 'expense', '#34495e', 'movie', NULL, 'monthly', 0, NULL, NULL, NULL, 7, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c292-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Kesehatan', 'expense', '#e67e22', 'local_hospital', NULL, 'monthly', 0, NULL, NULL, NULL, 8, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c2e6-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Pendidikan', 'expense', '#2980b9', 'school', NULL, 'monthly', 0, NULL, NULL, NULL, 9, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c36b-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Tabungan', 'expense', '#16a085', 'savings', NULL, 'monthly', 0, NULL, NULL, NULL, 10, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c3bb-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Tagihan & Utilitas', 'expense', '#95a5a6', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 11, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('97b8c40c-9fa6-11f0-9aee-bc0ff35ec8eb', NULL, 'Travel', 'expense', '#8e44ad', 'flight', NULL, 'monthly', 0, NULL, NULL, NULL, 12, 1, '2025-10-02 15:43:50', '2025-10-02 15:43:50'),
('9c839f78-3f63-4fae-b185-5f2dae1f83e1', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Kesehatan', 'expense', '#e67e22', 'local_hospital', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('9e650d7b-2582-4f4a-b8ac-c48993e053ff', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Tabungan', 'expense', '#16a085', 'savings', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('aa3f80cb-27cf-4e55-b685-bd77fa2af878', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Tagihan & Utilitas', 'expense', '#95a5a6', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('abb1f362-f727-418e-bb25-bf368d8b7c8d', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Makanan & Minuman', 'expense', '#e74c3c', 'restaurant', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('acd4cb09-ce8c-4e73-80ed-322f4a909295', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Belanja', 'expense', '#9b59b6', 'shopping_cart', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('ada0faf6-bbb9-461f-bcfc-063d2f3beff0', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Kesehatan', 'expense', '#e67e22', 'local_hospital', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('b4bcd446-4914-4b26-b376-ae7d900a12a4', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Investasi', 'income', '#27ae60', 'trending_up', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('ba6e2f4e-13f1-40dc-9530-3fb46a1d0142', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Kesehatan', 'expense', '#e67e22', 'local_hospital', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('bea508c6-3d14-4498-9b61-cf7c9bfa052d', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Food & Dining', 'expense', '#FF6B6B', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:05:35', '2025-10-29 11:05:35'),
('bf390b0e-076c-4b37-8566-d35e10c620fc', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Pendidikan', 'expense', '#2980b9', 'school', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('c1729238-6a38-4654-8ed0-e94174e5acbd', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Entertainment', 'expense', '#45B7D1', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:05:35', '2025-10-29 11:05:35'),
('c7b92b44-086c-4d5d-9033-b478e3794896', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Utilities', 'expense', '#96CEB4', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:05:35', '2025-10-29 11:05:35'),
('ca6a6639-bbab-4b5a-b45a-9c6ba8758bac', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Makanan & Minuman', 'expense', '#e74c3c', 'restaurant', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('cd0603ad-0160-438f-949e-dc92f1eed1cb', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Salary', 'income', '#FFEAA7', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('cd40f21a-0866-404c-8815-03acdd968187', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Gaji', 'income', '#2ecc71', 'work', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('d0bcf532-f59a-4c5d-9118-1668570719f5', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Tabungan', 'expense', '#16a085', 'savings', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('d13d1dab-ace7-467d-9192-c16f45e75936', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Tagihan & Utilitas', 'expense', '#95a5a6', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('d5f3eaaa-9f02-488a-a526-4dfd23c0543f', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Hiburan', 'expense', '#34495e', 'movie', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('da23ef8f-ad25-40ab-9f9a-e43446d20200', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Freelance', 'income', '#1abc9c', 'computer', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('de05fcf6-0e39-4263-afe9-a77d31bca245', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Utilities', 'expense', '#96CEB4', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 0, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('e26fdb47-908b-4197-98ab-8461fbc2c2ba', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Tagihan & Utilitas', 'expense', '#95a5a6', 'receipt', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:32:38', '2025-10-29 12:32:38'),
('ed97e04c-ed7a-48f1-b420-f81b9b51a2b2', '7d89af61-65df-4497-86a2-d4ba81c2ed35', 'Belanja', 'expense', '#9b59b6', 'shopping_cart', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 11:10:01', '2025-10-29 11:10:01'),
('f753fa9a-e767-495e-8695-1f14e4a4d3b7', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Pendidikan', 'expense', '#2980b9', 'school', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22'),
('fe45a0f6-04d1-4b7c-9b98-e2478dbcbf50', 'e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'Transportasi', 'expense', '#f39c12', 'directions_car', NULL, 'monthly', 0, NULL, NULL, NULL, 0, 1, '2025-10-29 12:29:22', '2025-10-29 12:29:22');

-- --------------------------------------------------------

--
-- Table structure for table `financial_goals_232143`
--

CREATE TABLE `financial_goals_232143` (
  `goal_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) NOT NULL,
  `name_232143` varchar(255) NOT NULL,
  `description_232143` text,
  `goal_type_232143` enum('emergency_fund','vacation','investment','debt_payment','education','vehicle','house','wedding','other') NOT NULL,
  `target_amount_232143` decimal(15,2) NOT NULL,
  `current_amount_232143` decimal(15,2) DEFAULT '0.00',
  `start_date_232143` date DEFAULT (curdate()),
  `target_date_232143` date NOT NULL,
  `is_completed_232143` tinyint(1) DEFAULT '0',
  `completed_date_232143` date DEFAULT NULL,
  `priority_232143` int DEFAULT '3',
  `monthly_target_232143` decimal(15,2) DEFAULT NULL,
  `auto_deduct_232143` tinyint(1) DEFAULT '0',
  `deduct_percentage_232143` decimal(5,2) DEFAULT NULL,
  `recommended_monthly_saving_232143` decimal(15,2) DEFAULT NULL,
  `feasibility_score_232143` decimal(3,2) DEFAULT NULL,
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `progress_percentage_232143` decimal(5,2) GENERATED ALWAYS AS ((case when (`target_amount_232143` > 0) then round(((`current_amount_232143` / `target_amount_232143`) * 100),2) else 0 end)) STORED
) ;

-- --------------------------------------------------------

--
-- Table structure for table `financial_obligations_232143`
--

CREATE TABLE `financial_obligations_232143` (
  `obligation_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) NOT NULL,
  `name_232143` varchar(255) NOT NULL,
  `type_232143` enum('bill','debt','subscription') NOT NULL,
  `category_232143` enum('utility','internet','phone','insurance','credit_card','personal_loan','mortgage','car_loan','student_loan','subscription','other') NOT NULL,
  `original_amount_232143` decimal(15,2) DEFAULT NULL,
  `current_balance_232143` decimal(15,2) DEFAULT NULL,
  `monthly_amount_232143` decimal(15,2) NOT NULL,
  `due_date_232143` int DEFAULT NULL,
  `start_date_232143` date DEFAULT NULL,
  `end_date_232143` date DEFAULT NULL,
  `next_payment_date_232143` date DEFAULT NULL,
  `interest_rate_232143` decimal(5,2) DEFAULT NULL,
  `minimum_payment_232143` decimal(15,2) DEFAULT NULL,
  `payoff_strategy_232143` enum('snowball','avalanche','minimum') DEFAULT NULL,
  `is_auto_pay_232143` tinyint(1) DEFAULT '0',
  `is_subscription_232143` tinyint(1) DEFAULT '0',
  `subscription_cycle_232143` enum('monthly','quarterly','yearly') DEFAULT NULL,
  `status_232143` enum('active','paid_off','cancelled','overdue') DEFAULT 'active',
  `priority_232143` enum('high','medium','low') DEFAULT 'medium',
  `reminder_days_before_232143` int DEFAULT '3',
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `financial_obligations_232143`
--

INSERT INTO `financial_obligations_232143` (`obligation_id_232143`, `user_id_232143`, `name_232143`, `type_232143`, `category_232143`, `original_amount_232143`, `current_balance_232143`, `monthly_amount_232143`, `due_date_232143`, `start_date_232143`, `end_date_232143`, `next_payment_date_232143`, `interest_rate_232143`, `minimum_payment_232143`, `payoff_strategy_232143`, `is_auto_pay_232143`, `is_subscription_232143`, `subscription_cycle_232143`, `status_232143`, `priority_232143`, `reminder_days_before_232143`, `created_at_232143`, `updated_at_232143`) VALUES
('1a9a2570-af23-4a4d-a1c5-90f6facf21cb', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Netflix Subscription', 'subscription', 'subscription', NULL, NULL, '15.99', 1, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 'monthly', 'active', 'medium', 3, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('23e593ac-e90e-4bb2-b914-ae242645f7b9', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Credit Card Debt', 'debt', 'credit_card', '5000.00', '3500.00', '250.00', 15, NULL, NULL, NULL, '18.50', '125.00', 'avalanche', 0, 0, NULL, 'active', 'medium', 3, '2025-10-29 11:05:36', '2025-10-29 11:05:36'),
('57997d3e-6b5d-4bb0-aa24-7d242a85633b', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Updated Test Debt', 'debt', 'other', NULL, NULL, '250.00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 'active', 'medium', 3, '2025-10-29 11:08:58', '2025-10-29 11:10:54'),
('885edd38-9fcf-4b6e-833d-935a1a20a131', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Test Debt', 'debt', 'other', NULL, NULL, '100.00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, NULL, 'active', 'medium', 3, '2025-10-29 10:59:28', '2025-10-29 10:59:28'),
('a172aaaf-d5f4-4a1a-a1d4-9cf7219ae0a0', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Credit Card Debt', 'debt', 'credit_card', '5000.00', '3500.00', '250.00', 15, NULL, NULL, NULL, '18.50', '125.00', 'avalanche', 0, 0, NULL, 'active', 'medium', 3, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('a6d2132b-d76c-4433-93c8-fafa35249683', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'Car Loan', 'debt', 'car_loan', '15000.00', '8500.00', '350.00', 20, NULL, NULL, NULL, '5.50', '350.00', 'snowball', 0, 0, NULL, 'active', 'medium', 3, '2025-10-29 11:06:20', '2025-10-29 11:06:20');

-- --------------------------------------------------------

--
-- Table structure for table `location_intelligence_232143`
--

CREATE TABLE `location_intelligence_232143` (
  `location_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `latitude_232143` decimal(10,8) NOT NULL,
  `longitude_232143` decimal(11,8) NOT NULL,
  `place_name_232143` varchar(255) NOT NULL,
  `place_type_232143` varchar(100) NOT NULL,
  `address_232143` text,
  `city_232143` varchar(100) DEFAULT NULL,
  `country_232143` varchar(100) DEFAULT 'Indonesia',
  `average_prices_232143` json NOT NULL,
  `price_ranges_232143` json DEFAULT NULL,
  `user_rating_232143` decimal(3,2) DEFAULT NULL,
  `popularity_score_232143` int DEFAULT '0',
  `total_reviews_232143` int DEFAULT '0',
  `opening_hours_232143` json DEFAULT NULL,
  `price_level_232143` int DEFAULT NULL,
  `total_transactions_232143` int DEFAULT '0',
  `last_updated_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `data_confidence_232143` decimal(3,2) DEFAULT '0.70',
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `notifications_232143`
--

CREATE TABLE `notifications_232143` (
  `notification_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) NOT NULL,
  `type_232143` enum('budget_alert','goal_progress','bill_reminder','spending_insight','system_announcement','security_alert') NOT NULL,
  `title_232143` varchar(255) NOT NULL,
  `message_232143` text NOT NULL,
  `action_url_232143` varchar(500) DEFAULT NULL,
  `action_label_232143` varchar(100) DEFAULT NULL,
  `is_read_232143` tinyint(1) DEFAULT '0',
  `is_sent_232143` tinyint(1) DEFAULT '0',
  `sent_at_232143` timestamp NULL DEFAULT NULL,
  `read_at_232143` timestamp NULL DEFAULT NULL,
  `priority_232143` enum('low','normal','high') DEFAULT 'normal',
  `category_232143` varchar(100) DEFAULT NULL,
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `obligation_payments_232143`
--

CREATE TABLE `obligation_payments_232143` (
  `payment_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `obligation_id_232143` varchar(36) NOT NULL,
  `user_id_232143` varchar(36) NOT NULL,
  `amount_paid_232143` decimal(15,2) NOT NULL,
  `payment_date_232143` date NOT NULL,
  `payment_method_232143` varchar(50) DEFAULT NULL,
  `principal_paid_232143` decimal(15,2) DEFAULT NULL,
  `interest_paid_232143` decimal(15,2) DEFAULT NULL,
  `transaction_id_232143` varchar(36) DEFAULT NULL,
  `status_232143` enum('completed','pending','failed') DEFAULT 'completed',
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `obligation_payments_232143`
--

INSERT INTO `obligation_payments_232143` (`payment_id_232143`, `obligation_id_232143`, `user_id_232143`, `amount_paid_232143`, `payment_date_232143`, `payment_method_232143`, `principal_paid_232143`, `interest_paid_232143`, `transaction_id_232143`, `status_232143`, `created_at_232143`) VALUES
('e37d9af3-2be1-4756-a3ad-a6a2dd094e75', '57997d3e-6b5d-4bb0-aa24-7d242a85633b', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '50.00', '2025-10-29', 'credit_card', NULL, NULL, NULL, 'completed', '2025-10-29 11:10:44');

-- --------------------------------------------------------

--
-- Table structure for table `spending_patterns_232143`
--

CREATE TABLE `spending_patterns_232143` (
  `pattern_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) NOT NULL,
  `pattern_type_232143` enum('weekly','monthly','seasonal','location_based','category_based') NOT NULL,
  `category_id_232143` varchar(36) DEFAULT NULL,
  `location_id_232143` varchar(36) DEFAULT NULL,
  `pattern_data_232143` json NOT NULL,
  `average_amount_232143` decimal(15,2) NOT NULL,
  `frequency_per_month_232143` decimal(5,2) DEFAULT NULL,
  `total_occurrences_232143` int DEFAULT '0',
  `last_occurrence_232143` date DEFAULT NULL,
  `confidence_score_232143` decimal(3,2) DEFAULT NULL,
  `is_active_232143` tinyint(1) DEFAULT '1',
  `detected_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `model_version_232143` varchar(50) DEFAULT NULL,
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `transactions_232143`
--

CREATE TABLE `transactions_232143` (
  `transaction_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `user_id_232143` varchar(36) NOT NULL,
  `amount_232143` decimal(15,2) NOT NULL,
  `type_232143` enum('income','expense','transfer') NOT NULL,
  `category_id_232143` varchar(36) DEFAULT NULL,
  `description_232143` varchar(500) NOT NULL,
  `location_data_232143` json DEFAULT NULL,
  `payment_method_232143` enum('cash','debit_card','credit_card','e_wallet','bank_transfer') DEFAULT 'cash',
  `receipt_image_url_232143` varchar(500) DEFAULT NULL,
  `is_recurring_232143` tinyint(1) DEFAULT '0',
  `recurring_pattern_232143` json DEFAULT NULL,
  `predicted_category_id_232143` varchar(36) DEFAULT NULL,
  `confidence_score_232143` decimal(3,2) DEFAULT NULL,
  `is_verified_232143` tinyint(1) DEFAULT '1',
  `tags_232143` json DEFAULT NULL,
  `transaction_date_232143` date NOT NULL,
  `transaction_time_232143` time DEFAULT NULL,
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ;

--
-- Dumping data for table `transactions_232143`
--

INSERT INTO `transactions_232143` (`transaction_id_232143`, `user_id_232143`, `amount_232143`, `type_232143`, `category_id_232143`, `description_232143`, `location_data_232143`, `payment_method_232143`, `receipt_image_url_232143`, `is_recurring_232143`, `recurring_pattern_232143`, `predicted_category_id_232143`, `confidence_score_232143`, `is_verified_232143`, `tags_232143`, `transaction_date_232143`, `transaction_time_232143`, `created_at_232143`, `updated_at_232143`) VALUES
('065bd810-5cba-4908-8717-11faa0b8f081', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '3000.00', 'income', '49a07475-f591-42d8-8c7e-90a89a0f492a', 'Monthly salary', NULL, 'bank_transfer', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-24', NULL, '2025-10-29 11:05:36', '2025-10-29 11:05:35'),
('19913d20-9157-4651-9352-40e00d2c6ffd', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '75.00', 'expense', NULL, 'Test transaction', NULL, 'cash', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-29', NULL, '2025-10-29 11:11:58', '2025-10-29 11:11:57'),
('26937507-8775-4de3-9eb8-1b60a3acb5ea', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '45.00', 'expense', 'c1729238-6a38-4654-8ed0-e94174e5acbd', 'Movie tickets', NULL, 'debit_card', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-26', NULL, '2025-10-29 11:05:36', '2025-10-29 11:05:35'),
('2caa9580-6742-48f4-9d32-c7e16fd47cd2', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', '1000.00', 'income', NULL, 'a', NULL, 'cash', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-11-03', NULL, '2025-11-02 22:30:58', '2025-11-02 22:30:57'),
('38e9e6e4-4bcc-44da-9cb2-375e93fe3eec', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', '1000.00', 'income', NULL, 'a', NULL, 'cash', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-11-03', NULL, '2025-11-02 22:08:46', '2025-11-02 22:08:45'),
('54964383-cd08-4e5a-9ea7-a480135dbfdd', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '25.50', 'expense', 'bea508c6-3d14-4498-9b61-cf7c9bfa052d', 'Lunch at restaurant', NULL, 'debit_card', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-28', NULL, '2025-10-29 11:05:36', '2025-10-29 11:05:35'),
('58c798bc-9774-408f-a5d2-38aee68e2687', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '150.00', 'expense', '63fb57d5-8c51-46d5-bab7-ac56dc5ff038', 'Gas station', NULL, 'debit_card', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-27', NULL, '2025-10-29 11:05:36', '2025-10-29 11:05:35'),
('6e1d2d03-a4e9-4a7b-b266-a89a51c40da9', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', '1000.00', 'income', NULL, 'a', NULL, 'cash', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-11-03', NULL, '2025-11-02 22:29:05', '2025-11-02 22:29:05'),
('82fe80be-366b-46da-87ae-6a0164f5916c', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '3000.00', 'income', 'cd0603ad-0160-438f-949e-dc92f1eed1cb', 'Monthly salary', NULL, 'bank_transfer', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-24', NULL, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('b18e1a40-aa10-45e0-ae50-7cfed742d705', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '25.50', 'expense', '07f2295f-8244-49ab-a509-ae260f059f7f', 'Lunch at restaurant', NULL, 'debit_card', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-28', NULL, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('ba999e1a-2674-478f-912e-876944ee11d7', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '150.00', 'expense', '94eaf908-a8a5-4fe4-90d9-d75102134414', 'Gas station', NULL, 'debit_card', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-27', NULL, '2025-10-29 11:06:20', '2025-10-29 11:06:20'),
('d15d8d19-f08f-4b32-9ef8-95c36ea929a3', '5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', '100.00', 'income', NULL, 'a', NULL, 'cash', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-11-02', NULL, '2025-11-02 13:15:17', '2025-11-02 13:15:17'),
('df2e7d5c-4707-4055-96cc-dda6ff53b1af', 'ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', '45.00', 'expense', '7e1d6d5b-3934-4695-b280-c2c88be52b8d', 'Movie tickets', NULL, 'debit_card', NULL, 0, NULL, NULL, NULL, 1, NULL, '2025-10-26', NULL, '2025-10-29 11:06:20', '2025-10-29 11:06:20');

--
-- Triggers `transactions_232143`
--
DELIMITER $$
CREATE TRIGGER `after_transaction_insert_232143` AFTER INSERT ON `transactions_232143` FOR EACH ROW BEGIN
    IF NEW.type_232143 = 'expense' AND NEW.category_id_232143 IS NOT NULL THEN
        UPDATE budgets_232143 
        SET spent_amount_232143 = (
            SELECT COALESCE(SUM(amount_232143), 0)
            FROM transactions_232143 t
            WHERE t.category_id_232143 = NEW.category_id_232143
            AND t.transaction_date_232143 BETWEEN budgets_232143.period_start_232143 AND budgets_232143.period_end_232143
            AND t.type_232143 = 'expense'
        )
        WHERE category_id_232143 = NEW.category_id_232143
        AND period_start_232143 <= NEW.transaction_date_232143 
        AND period_end_232143 >= NEW.transaction_date_232143;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `users_232143`
--

CREATE TABLE `users_232143` (
  `user_id_232143` varchar(36) NOT NULL DEFAULT (uuid()),
  `email_232143` varchar(255) NOT NULL,
  `password_hash_232143` varchar(255) NOT NULL,
  `full_name_232143` varchar(255) NOT NULL,
  `phone_number_232143` varchar(20) DEFAULT NULL,
  `date_of_birth_232143` date DEFAULT NULL,
  `occupation_232143` varchar(100) DEFAULT NULL,
  `income_range_232143` enum('0-3jt','3-5jt','5-10jt','10-20jt','20jt+') DEFAULT NULL,
  `family_size_232143` int DEFAULT '1',
  `currency_232143` varchar(10) DEFAULT 'IDR',
  `base_location_232143` json DEFAULT NULL,
  `financial_goals_232143` json DEFAULT (_utf8mb4'{\r\n        "emergency_fund": 0,\r\n        "vacation": 0, \r\n        "investment": 0,\r\n        "debt_payment": 0\r\n    }'),
  `risk_tolerance_232143` int DEFAULT '3',
  `notification_settings_232143` json DEFAULT (_utf8mb4'{\r\n        "budget_alerts": true,\r\n        "goal_reminders": true,\r\n        "spending_insights": true,\r\n        "push_notifications": true\r\n    }'),
  `created_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at_232143` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login_232143` timestamp NULL DEFAULT NULL,
  `is_active_232143` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users_232143`
--

INSERT INTO `users_232143` (`user_id_232143`, `email_232143`, `password_hash_232143`, `full_name_232143`, `phone_number_232143`, `date_of_birth_232143`, `occupation_232143`, `income_range_232143`, `family_size_232143`, `currency_232143`, `base_location_232143`, `financial_goals_232143`, `risk_tolerance_232143`, `notification_settings_232143`, `created_at_232143`, `updated_at_232143`, `last_login_232143`, `is_active_232143`) VALUES
('1750058a-9408-4f79-926b-37113be5529e', 'anotheruser@example.com', '$2b$12$ICC23HJs4JbCUP88FwgxSeT0n4BRZ8FS2kw8h5seMmfdxlKbb73hK', 'Another User', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 11:09:51', '2025-10-29 11:09:50', NULL, 1),
('306a3434-d3bd-4727-b42d-8943825ee8d5', 'newuser@example.com', '$2b$12$dC7xZu7XkVpqFA8Fn9GZwO4lrDzf4YQLXMHS8QmfOGnkCh3JeWn0O', 'New User', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 11:09:20', '2025-10-29 11:09:20', NULL, 1),
('5284d4d6-e197-4053-a902-b4b7f7ee5e20', 'asa@gmail.com', '$2b$12$sqV3ZOItsnNGwWbqgIucrui/h8Vv7E82LJ6Weqh2sD4K7OV46jLQC', 'das', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 11:51:46', '2025-10-29 11:51:45', NULL, 1),
('5ae93c37-b4c3-11f0-815b-bc0ff35ec8eb', 'Q@gmail.com', '$2b$12$Qb9lmZS1.QvD/oF2h6ubfe22lyoOwcNlWximKwTChdrwlBO7aq0e2', 'ada', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 12:32:39', '2025-11-03 00:05:00', '2025-11-03 00:05:00', 1),
('71fa0c62-66f2-4e10-a5e5-791cb80647ce', 'asda@gmail.com', '$2b$12$njSsU35.9t5.Pz09ryDlU.GonVGhOHGTcdUCR5ILHqtuo0acXWOeq', 'das', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 11:50:16', '2025-10-29 11:50:16', NULL, 1),
('769d87ce-9e5c-4705-9744-99a26f06e5a4', 'test2@example.com', '$2b$12$hrY2fqyZ.qqBSPZTqIzbLukTTPsj7tl2Iq8bJ18W90saItyGn6rtK', '', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 10:58:47', '2025-10-29 10:58:46', NULL, 1),
('7d89af61-65df-4497-86a2-d4ba81c2ed35', 'testreg@example.com', '$2b$12$4F4S8M83LMxGiUVOnulrFe9xXYCRYboX24qrYdyTZfUtoc3no7shi', 'Test Reg', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 11:10:01', '2025-10-29 11:10:07', '2025-10-29 11:10:07', 1),
('e651e739-b4c2-11f0-815b-bc0ff35ec8eb', 'a@gmail.com', '$2b$12$kNwg.yZd6d9vNOJdmPQmPuIyY.G34B8yY8QllhIiH72BSi7ydsOmS', 'ad', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 12:29:23', '2025-10-29 12:29:22', NULL, 1),
('ff42a623-53be-4bbb-a3a1-ab4ebbb83bdf', 'test@example.com', '$2b$12$VeJ4wWk3EtLDBHSCGu6sxeyW/mVrwaLlQ1fdZAYZD97S4wUdJE9xS', '', NULL, NULL, NULL, NULL, 1, 'IDR', NULL, '{\"vacation\": 0, \"investment\": 0, \"debt_payment\": 0, \"emergency_fund\": 0}', 3, '{\"budget_alerts\": true, \"goal_reminders\": true, \"spending_insights\": true, \"push_notifications\": true}', '2025-10-29 10:58:13', '2025-10-29 11:07:45', '2025-10-29 11:07:45', 1);

-- --------------------------------------------------------

--
-- Stand-in structure for view `user_financial_summary_232143`
-- (See below for the actual view)
--
CREATE TABLE `user_financial_summary_232143` (
`user_id_232143` varchar(36)
,`full_name_232143` varchar(255)
,`income_range_232143` enum('0-3jt','3-5jt','5-10jt','10-20jt','20jt+')
,`monthly_income_232143` decimal(37,2)
,`monthly_expenses_232143` decimal(37,2)
,`active_budgets_count_232143` bigint
,`average_goal_progress_232143` decimal(9,6)
);

-- --------------------------------------------------------

--
-- Structure for view `user_financial_summary_232143`
--
DROP TABLE IF EXISTS `user_financial_summary_232143`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `user_financial_summary_232143`  AS SELECT `u`.`user_id_232143` AS `user_id_232143`, `u`.`full_name_232143` AS `full_name_232143`, `u`.`income_range_232143` AS `income_range_232143`, coalesce((select sum(`t`.`amount_232143`) from `transactions_232143` `t` where ((`t`.`user_id_232143` = `u`.`user_id_232143`) and (`t`.`type_232143` = 'income') and (`t`.`transaction_date_232143` >= (curdate() - interval 30 day)))),0) AS `monthly_income_232143`, coalesce((select sum(`t`.`amount_232143`) from `transactions_232143` `t` where ((`t`.`user_id_232143` = `u`.`user_id_232143`) and (`t`.`type_232143` = 'expense') and (`t`.`transaction_date_232143` >= (curdate() - interval 30 day)))),0) AS `monthly_expenses_232143`, (select count(0) from `budgets_232143` `b` where ((`b`.`user_id_232143` = `u`.`user_id_232143`) and (`b`.`is_active_232143` = true) and (curdate() between `b`.`period_start_232143` and `b`.`period_end_232143`))) AS `active_budgets_count_232143`, (select avg(`fg`.`progress_percentage_232143`) from `financial_goals_232143` `fg` where ((`fg`.`user_id_232143` = `u`.`user_id_232143`) and (`fg`.`is_completed_232143` = false))) AS `average_goal_progress_232143` FROM `users_232143` AS `u` WHERE (`u`.`is_active_232143` = true)  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ai_recommendations_232143`
--
ALTER TABLE `ai_recommendations_232143`
  ADD PRIMARY KEY (`recommendation_id_232143`),
  ADD KEY `idx_recommendations_user_232143` (`user_id_232143`),
  ADD KEY `idx_recommendations_type_232143` (`type_232143`),
  ADD KEY `idx_recommendations_urgency_232143` (`urgency_232143`),
  ADD KEY `idx_recommendations_unread_232143` (`is_read_232143`),
  ADD KEY `idx_recommendations_created_232143` (`created_at_232143`);

--
-- Indexes for table `bill_payments_232143`
--
ALTER TABLE `bill_payments_232143`
  ADD PRIMARY KEY (`payment_id_232143`),
  ADD KEY `bill_id_232143` (`bill_id_232143`),
  ADD KEY `user_id_232143` (`user_id_232143`),
  ADD KEY `transaction_id_232143` (`transaction_id_232143`);

--
-- Indexes for table `budgets_232143`
--
ALTER TABLE `budgets_232143`
  ADD PRIMARY KEY (`budget_id_232143`),
  ADD KEY `idx_budgets_user_id_232143` (`user_id_232143`),
  ADD KEY `idx_budgets_period_232143` (`period_start_232143`,`period_end_232143`),
  ADD KEY `idx_budgets_active_232143` (`is_active_232143`),
  ADD KEY `idx_budgets_category_232143` (`category_id_232143`);

--
-- Indexes for table `categories_232143`
--
ALTER TABLE `categories_232143`
  ADD PRIMARY KEY (`category_id_232143`),
  ADD KEY `parent_category_id_232143` (`parent_category_id_232143`),
  ADD KEY `idx_categories_user_id_232143` (`user_id_232143`),
  ADD KEY `idx_categories_type_232143` (`type_232143`),
  ADD KEY `idx_categories_system_232143` (`is_system_default_232143`);

--
-- Indexes for table `financial_goals_232143`
--
ALTER TABLE `financial_goals_232143`
  ADD PRIMARY KEY (`goal_id_232143`),
  ADD KEY `idx_goals_user_id_232143` (`user_id_232143`),
  ADD KEY `idx_goals_target_date_232143` (`target_date_232143`),
  ADD KEY `idx_goals_completed_232143` (`is_completed_232143`),
  ADD KEY `idx_goals_type_232143` (`goal_type_232143`);

--
-- Indexes for table `financial_obligations_232143`
--
ALTER TABLE `financial_obligations_232143`
  ADD PRIMARY KEY (`obligation_id_232143`),
  ADD KEY `user_id_232143` (`user_id_232143`);

--
-- Indexes for table `location_intelligence_232143`
--
ALTER TABLE `location_intelligence_232143`
  ADD PRIMARY KEY (`location_id_232143`),
  ADD KEY `idx_location_coords_232143` (`latitude_232143`,`longitude_232143`),
  ADD KEY `idx_location_type_232143` (`place_type_232143`),
  ADD KEY `idx_location_city_232143` (`city_232143`),
  ADD KEY `idx_location_confidence_232143` (`data_confidence_232143`);

--
-- Indexes for table `notifications_232143`
--
ALTER TABLE `notifications_232143`
  ADD PRIMARY KEY (`notification_id_232143`),
  ADD KEY `idx_notifications_user_232143` (`user_id_232143`),
  ADD KEY `idx_notifications_type_232143` (`type_232143`),
  ADD KEY `idx_notifications_unread_232143` (`is_read_232143`),
  ADD KEY `idx_notifications_created_232143` (`created_at_232143`),
  ADD KEY `idx_notifications_priority_232143` (`priority_232143`);

--
-- Indexes for table `obligation_payments_232143`
--
ALTER TABLE `obligation_payments_232143`
  ADD PRIMARY KEY (`payment_id_232143`),
  ADD KEY `obligation_id_232143` (`obligation_id_232143`),
  ADD KEY `user_id_232143` (`user_id_232143`),
  ADD KEY `transaction_id_232143` (`transaction_id_232143`);

--
-- Indexes for table `spending_patterns_232143`
--
ALTER TABLE `spending_patterns_232143`
  ADD PRIMARY KEY (`pattern_id_232143`),
  ADD KEY `location_id_232143` (`location_id_232143`),
  ADD KEY `idx_patterns_user_232143` (`user_id_232143`),
  ADD KEY `idx_patterns_type_232143` (`pattern_type_232143`),
  ADD KEY `idx_patterns_active_232143` (`is_active_232143`),
  ADD KEY `idx_patterns_category_232143` (`category_id_232143`);

--
-- Indexes for table `transactions_232143`
--
ALTER TABLE `transactions_232143`
  ADD PRIMARY KEY (`transaction_id_232143`),
  ADD KEY `predicted_category_id_232143` (`predicted_category_id_232143`),
  ADD KEY `idx_transactions_user_id_232143` (`user_id_232143`),
  ADD KEY `idx_transactions_date_232143` (`transaction_date_232143`),
  ADD KEY `idx_transactions_category_232143` (`category_id_232143`),
  ADD KEY `idx_transactions_type_232143` (`type_232143`),
  ADD KEY `idx_transactions_recurring_232143` (`is_recurring_232143`),
  ADD KEY `idx_transactions_created_232143` (`created_at_232143`);

--
-- Indexes for table `users_232143`
--
ALTER TABLE `users_232143`
  ADD PRIMARY KEY (`user_id_232143`),
  ADD UNIQUE KEY `email_232143` (`email_232143`),
  ADD KEY `idx_users_email_232143` (`email_232143`),
  ADD KEY `idx_users_created_at_232143` (`created_at_232143`),
  ADD KEY `idx_users_active_232143` (`is_active_232143`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `ai_recommendations_232143`
--
ALTER TABLE `ai_recommendations_232143`
  ADD CONSTRAINT `ai_recommendations_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE;

--
-- Constraints for table `bill_payments_232143`
--
ALTER TABLE `bill_payments_232143`
  ADD CONSTRAINT `bill_payments_232143_ibfk_1` FOREIGN KEY (`bill_id_232143`) REFERENCES `bills_232143` (`bill_id_232143`) ON DELETE CASCADE,
  ADD CONSTRAINT `bill_payments_232143_ibfk_2` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE,
  ADD CONSTRAINT `bill_payments_232143_ibfk_3` FOREIGN KEY (`transaction_id_232143`) REFERENCES `transactions_232143` (`transaction_id_232143`);

--
-- Constraints for table `budgets_232143`
--
ALTER TABLE `budgets_232143`
  ADD CONSTRAINT `budgets_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE,
  ADD CONSTRAINT `budgets_232143_ibfk_2` FOREIGN KEY (`category_id_232143`) REFERENCES `categories_232143` (`category_id_232143`);

--
-- Constraints for table `categories_232143`
--
ALTER TABLE `categories_232143`
  ADD CONSTRAINT `categories_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE,
  ADD CONSTRAINT `categories_232143_ibfk_2` FOREIGN KEY (`parent_category_id_232143`) REFERENCES `categories_232143` (`category_id_232143`);

--
-- Constraints for table `financial_goals_232143`
--
ALTER TABLE `financial_goals_232143`
  ADD CONSTRAINT `financial_goals_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE;

--
-- Constraints for table `financial_obligations_232143`
--
ALTER TABLE `financial_obligations_232143`
  ADD CONSTRAINT `financial_obligations_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE;

--
-- Constraints for table `notifications_232143`
--
ALTER TABLE `notifications_232143`
  ADD CONSTRAINT `notifications_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE;

--
-- Constraints for table `obligation_payments_232143`
--
ALTER TABLE `obligation_payments_232143`
  ADD CONSTRAINT `obligation_payments_232143_ibfk_1` FOREIGN KEY (`obligation_id_232143`) REFERENCES `financial_obligations_232143` (`obligation_id_232143`),
  ADD CONSTRAINT `obligation_payments_232143_ibfk_2` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`),
  ADD CONSTRAINT `obligation_payments_232143_ibfk_3` FOREIGN KEY (`transaction_id_232143`) REFERENCES `transactions_232143` (`transaction_id_232143`);

--
-- Constraints for table `spending_patterns_232143`
--
ALTER TABLE `spending_patterns_232143`
  ADD CONSTRAINT `spending_patterns_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE,
  ADD CONSTRAINT `spending_patterns_232143_ibfk_2` FOREIGN KEY (`category_id_232143`) REFERENCES `categories_232143` (`category_id_232143`),
  ADD CONSTRAINT `spending_patterns_232143_ibfk_3` FOREIGN KEY (`location_id_232143`) REFERENCES `location_intelligence_232143` (`location_id_232143`);

--
-- Constraints for table `transactions_232143`
--
ALTER TABLE `transactions_232143`
  ADD CONSTRAINT `transactions_232143_ibfk_1` FOREIGN KEY (`user_id_232143`) REFERENCES `users_232143` (`user_id_232143`) ON DELETE CASCADE,
  ADD CONSTRAINT `transactions_232143_ibfk_2` FOREIGN KEY (`category_id_232143`) REFERENCES `categories_232143` (`category_id_232143`),
  ADD CONSTRAINT `transactions_232143_ibfk_3` FOREIGN KEY (`predicted_category_id_232143`) REFERENCES `categories_232143` (`category_id_232143`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
