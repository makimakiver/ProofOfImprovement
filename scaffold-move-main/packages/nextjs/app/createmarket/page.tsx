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
    participants: ["0x72e23faea40ad11c7cb9c3a7e680c356e3335e54a3cf37541735c4d5851cac4f"],
    nameOfTicket: ["Test A", "Test B"],
    gradeTypes: ["A", "B"],
    endDate: "2025-12-31"
  };

  // Local state for each field
  const [triger, setTriger] = useState(false);
  const [title, setTitle] = useState("");
  const [participantInput, setParticipantInput] = useState("");
  const [participants, setParticipants] = useState<string[]>([]);
  const [gradeTypeInput, setGradeTypeInput] = useState("");
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
      await submitTransaction("new_create_market_place", [title, participants, gradeNames, gradeTypes, "0x860d08369d439bcca445a7336e38e5fbe4cad3de4dff1727faae0e5a6607bf27"]);

      if (transactionResponse?.transactionSubmitted) {
        console.log("Transaction successful:", transactionResponse.success ? "success" : "failed");
      }
    } catch (error) {
      console.error("Error creating market place:", error);
    }
    
    console.log(title, participants, gradeNames, gradeTypes, "0x860d08369d439bcca445a7336e38e5fbe4cad3de4dff1727faae0e5a6607bf27");

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
