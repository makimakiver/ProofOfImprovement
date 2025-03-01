"use client";
import React, { useState } from "react";
import type { NextPage } from "next";
import styles from "./page.module.css";
import { useRouter } from "next/navigation";
import useSubmitTransaction from "~~/hooks/scaffold-move/useSubmitTransaction";

const MarketCreatePage: NextPage = () => {
  const router = useRouter();

  const { submitTransaction, transactionResponse, transactionInProcess } = useSubmitTransaction("TestMarketAbstraction");

  // ----- Hardcoded "previous market" data -----
  const previousMarketData = {
    title: "Math Test",
    participants:  ["0x86960a9e820d43238e6b0034153acc599b23c2628f4036f1982e1cf45903fb36", "0x142f8257d95c7a9de19cd3e753b4fc6ea22d02739bdef27ddb94be0546bd61da", "0x5c92415defbe8124336f1bbfae06639da7446845d7bb4b7bc985ee608dd89312", "0x641f3b46e82c3fd05fe041a76f63970e5f3e38bcf0d4f5532a7040cf5e046955"],
    nameOfTicket: ["Test A", "Test B", "Test C", "Test F"],
    gradeTypes: ["A", "B", "C", "F"],
    endDate: "2025-12-31"
  };

  // Local state for each field
  const [triger, setTriger] = useState(false);
  const [title, setTitle] = useState("");
  const [participantInput, setParticipantInput] = useState("");
  const [participants, setParticipants] = useState<string[]>([]);
  const [gradeTypeInput, setGradeTypeInput] = useState("");
  const [gradeNameInput, setGradeNameInput] = useState("");
  const [gradeTypes, setGradeTypes] = useState<string[]>([]);
  const [gradeNames, setGradeNames] = useState<string[]>([]);
  const [endDate, setEndDate] = useState("");

  // Handler to load the previous market format
  const handleUsePreviousMarket = () => {
    if(triger){
      setTriger(false);
      setTitle("");
      setParticipants([]);
      setGradeTypes([]);
      setEndDate("");
      setGradeNames([]);
    }
    else{ 
      setTriger(true);
      setTitle(previousMarketData.title);
      setParticipants(previousMarketData.participants);
      setGradeTypes(previousMarketData.gradeTypes);
      setEndDate(previousMarketData.endDate);
      setGradeNames(previousMarketData.nameOfTicket)
    }
  };

  // Handlers for adding multiple participants
  const handleAddParticipant = () => {
    if (participantInput.trim()) {
      setParticipants([...participants, participantInput.trim()]);
      setParticipantInput("");
    }
  };

  // Handlers for adding multiple grade names
  const handleAddNamesType = () => {
    if (gradeNameInput.trim()) {
      setGradeNames([...gradeNames, gradeNameInput.trim()]);
      setGradeNameInput("");
    }
  };

  // Handlers for adding multiple grade types
  const handleAddGradeType = () => {
    if (gradeTypeInput.trim()) {
      setGradeTypes([...gradeTypes, gradeTypeInput.trim()]);
      setGradeTypeInput("");
    }
  };

  // Form submission handler
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    try {
      await submitTransaction("new_create_market_place", [title, participants, gradeNames, gradeTypes, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS]);

      if (transactionResponse?.transactionSubmitted) {
        console.log("Transaction successful:", transactionResponse.success ? "success" : "failed");
      }
    } catch (error) {
      console.error("Error creating market place:", error);
    }
    
    console.log(title, participants, gradeNames, gradeTypes, process.env.NEXT_PUBLIC_REGISTRY_ACCOUNT_ADDRESS);

    //router.push("/")
  };

  return (
    <div className={styles.container}>
      <div className={styles.formOutline}>
        <h1 className={styles.formTitle}>Create a Marketplace</h1>
        <form onSubmit={handleSubmit}>
          {/* Title */}
          <div className={styles.formField}>
            <label className={styles.label}>Title</label>
            <input
              type="text"
              className={styles.inputField}
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter market title"
            />
          </div>

          {/* Participants */}
          <div className={styles.formField}>
            <label className={styles.label}>Add participants</label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                className={`${styles.inputField} flex-grow`}
                value={participantInput}
                onChange={(e) => setParticipantInput(e.target.value)}
                placeholder="Enter participant wallet"
              />
              <button
                type="button"
                className={styles.addButton}
                onClick={handleAddParticipant}
              >
                +
              </button>
            </div>
            <ul className={styles.participantList}>
              {participants.map((p, idx) => (
                <li key={idx}>{p}</li>
              ))}
            </ul>
          </div>

          {/* Grade Names */}
          <div className={styles.formField}>
            <label className={styles.label}>Grade Names</label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                className={`${styles.inputField} flex-grow`}
                value={gradeNameInput}
                onChange={(e) => setGradeNameInput(e.target.value)}
                placeholder="e.g. Test-A, Test-B, Test-Pass, etc."
              />
              <button
                type="button"
                className={styles.addButton}
                onClick={handleAddNamesType}
              >
                +
              </button>
            </div>
            <ul className={styles.gradeList}>
              {gradeNames.map((g, idx) => (
                <li key={idx}>{g}</li>
              ))}
            </ul>
          </div>

          {/* Grade Types */}
          <div className={styles.formField}>
            <label className={styles.label}>Grade Types</label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                className={`${styles.inputField} flex-grow`}
                value={gradeTypeInput}
                onChange={(e) => setGradeTypeInput(e.target.value)}
                placeholder="e.g. A, B, Pass, etc."
              />
              <button
                type="button"
                className={styles.addButton}
                onClick={handleAddGradeType}
              >
                +
              </button>
            </div>
            <ul className={styles.gradeList}>
              {gradeTypes.map((g, idx) => (
                <li key={idx}>{g}</li>
              ))}
            </ul>
          </div>

          {/* End Date */}
          <div className={styles.formField}>
            <label className={styles.label}>End Date</label>
            <input
              type="date"
              className={styles.inputField}
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
            />
          </div>
          {/* Button to load "previous" market data */}
          <button
            type="button"
            className={styles.prevMarketBtn}
            onClick={handleUsePreviousMarket}
          >
            {triger ? "Clear" : "Use Previous Market Format"}
          </button>

          {/* Submit Button */}
          <button type="submit" className={styles.submitBtn}>
            Submit
          </button>

        </form>
      </div>
    </div>
  );
};

export default MarketCreatePage;
